#!/usr/bin/env julia

# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# CLI tool for to manage through Raytracer.jl package the generation
# and rendering of photorealistic images


using Pkg
Pkg.activate(normpath(@__DIR__))

using Raytracer

using ArgParse, ProgressMeter
using FileIO:
    File, @format_str, query


###########
# ArgParse


function print_error(args...)
    printstyled("Error: ", bold=true, color=:red)
    print(args..., "\n")
end

function parse_commandline_error_handler(settings::ArgParseSettings, err, err_code::Int = 1)
    if "out of range input for" |> occursin(err.text)
        s = reduce(replace, ["out of range input for " => "", " " => ""], init=err.text)
        parameter, value = split(s, ":")
        if parameter == "input_file"
            print_error("the parameter \"$(parameter)\" (value: $(value)) must be a PFM file")
        elseif parameter ∈ ["--alpha", "-a", "--gamma", "-g", "--luminosity", "-l", "--delta-t", "--n-frames", "--fps", "-f"]
            print_error("the parameter \"$(parameter)\" (value: $(value)) must be > 0")
        elseif parameter == "time-limits"
            print_error("the parameter \"$(parameter)\" (value: $(value)) must be composed of 2 Float32 values divided by a ':' (e.g., \"0:10\")")
        else
            print_error(err.text)
        end
    else
        print_error(err.text)
    end

    println(stderr, "\n", usage_string(settings), "\n")
    exit(err_code)
end


function parse_commandline()
    s = ArgParseSettings()
    s.description = "Raytracing for the generation of photorealistic images in Julia."
    s.exc_handler = parse_commandline_error_handler
    s.version = "Raytracer.jl version: $(@project_version)"
    s.add_version = true

    # main

    @add_arg_table! s begin
        "render"
            action = :command
            help = "render an image from a SceneLang script"
        "tonemapping"
            action = :command
            help = "apply tone mapping to a pfm image and save it to file"
        "docs"
            action = :command
            help = "show the documentation link"
    end

    # render

    s["render"].description = "Render an image from a SceneLang script."
    @add_arg_table! s["render"] begin
        "image"
            action = :command
            help = "render an image from a SceneLang script"
        "animation"
            action = :command
            help = "create an animation as mp4 video from a SceneLang script (require ffmpeg)"
    end

    # render image

    s["render"]["image"].description = "Render an image from a SceneLang script."
    @add_arg_table! s["render"]["image"] begin
        "input-script"
            help = "path to the input SceneLang script"
            arg_type = String
            range_tester = x -> x[end-2:end] == ".sl"
            required = true
        "--output-file", "-O"
            help = "output image name, without extension"
            arg_type = String
            default = "out"
        "--time", "-t"
            help = "time for script"
            arg_type = Float32
            default = 0f0
        "--force", "-f"
            help = "force overwrite"
            action = :store_true
    end
    add_arg_group!(s["render"]["image"], "tonemapping");
    @add_arg_table! s["render"]["image"] begin
        "--with-tonemapping"
            help = "apply the tone mapping process"
            action = :store_true
        "--ldr-extension", "-e"
            help = "only with \"--with-tonemapping\": extension of the generated ldr image (e.g., \"jpg\" or \"png\")"
            arg_type = String
            default = "jpg"
        "--alpha", "-a"
            help = "only with \"--with-tonemapping\": scaling factor for the normalization process"
            arg_type = Float32
            default = 0.75f0
            range_tester = x -> x > 0
        "--gamma", "-g"
            help = "only with \"--with-tonemapping\": gamma value for the tone mapping process"
            arg_type = Float32
            default = 1f0
            range_tester = x -> x > 0
        "--luminosity", "-l"
            help = "only with \"--with-tonemapping\": luminosity for the tone mapping process (-1 = auto)"
            arg_type = Float32
            default = -1f0
            range_tester = x -> x == -1 || x > 0
    end

    # render animation

    s["render"]["animation"].description = "Create an animation as mp4 video from a SceneLang script (require ffmpeg)."
    @add_arg_table! s["render"]["animation"] begin
        "input-script"
            help = "path to the input SceneLang script"
            arg_type = String
            range_tester = x -> x[end-2:end] == ".sl"
            required = true
        "time-limits"
            help = "time limits as \"t_start:t_end\" (e.g., \"0:10\")"
            arg_type = String
            range_tester = x -> (y=Tuple(parse.(Float32, split(x, ":"))); length(y) == 2)
            required = true
        "--output-dir", "-F"
            help = "output directory"
            arg_type = String
            default = "animation"
        "--output-file", "-O"
            help = "name of saved frames and video, without extension"
            arg_type = String
            default = "out"
        "--force", "-f"
            help = "force overwrite"
            action = :store_true
        "--fps", "-r"
            help = "FPS (frame-per-second) of the output video"
            arg_type = Int
            default = 15
            range_tester = x -> x > 0
    end
    add_arg_group!(s["render"]["animation"], "delta animation (mutually exclusive)", exclusive=true, required=true);
    @add_arg_table! s["render"]["animation"] begin
        "--delta-t"
            help = "proceed from \"t_start\" to \"t_end\" in steps of \"delta-t\""
            arg_type = Float32
            range_tester = x -> x > 0
        "--n-frames"
            help = "number of frames between \"t_start\" and \"t_end\""
            arg_type = Int
            range_tester = x -> x > 0
    end
    add_arg_group!(s["render"]["animation"], "tonemapping");
    @add_arg_table! s["render"]["animation"] begin
        "--ldr-extension", "-e"
            help = "only with \"--with-tonemapping\": extension of the generated ldr image (e.g., \"jpg\" or \"png\")"
            arg_type = String
            default = "jpg"
        "--alpha", "-a"
            help = "only with \"--with-tonemapping\": scaling factor for the normalization process"
            arg_type = Float32
            default = 0.75f0
            range_tester = x -> x > 0
        "--gamma", "-g"
            help = "only with \"--with-tonemapping\": gamma value for the tone mapping process"
            arg_type = Float32
            default = 1f0
            range_tester = x -> x > 0
        "--luminosity", "-l"
            help = "only with \"--with-tonemapping\": luminosity for the tone mapping process (-1 = auto)"
            arg_type = Float32
            default = -1f0
            range_tester = x -> x == -1 || x > 0
    end

    # tonemapping

    s["tonemapping"].description = "Apply tone mapping to a pfm image and save it to file."
    @add_arg_table! s["tonemapping"] begin
        "input-file"
            help = "path to input file, it must be a PFM file"
            arg_type = String
            range_tester = x -> typeof(query(x))<:File{format"PFM"}
            required = true
        "output-file"
            help = "output file name"
            arg_type = String
            required = true
        "--force", "-f"
            help = "force overwrite"
            action = :store_true
    end
    add_arg_group!(s["tonemapping"], "tonemapping settings");
    @add_arg_table! s["tonemapping"] begin
        "--alpha", "-a"
            help = "scaling factor for the normalization process"
            arg_type = Float32
            default = 0.5f0
            range_tester = x -> x > 0
        "--gamma", "-g"
            help = "gamma value for the tone mapping process"
            arg_type = Float32
            default = 1f0
            range_tester = x -> x > 0
        "--luminosity", "-l"
            help = "only with \"--with-tonemapping\": luminosity for the tone mapping process (-1 = auto)"
            arg_type = Float32
            default = -1f0
            range_tester = x -> x == -1 || x > 0
    end

    # docs

    s["docs"].description = "Show the documentation link."
    @add_arg_table! s["docs"] begin
        "--dev"
            help = "documentation of the dev version"
            action = :store_true
    end

    # end

    parse_args(s)
end


####################
# Utility functions


function renderimage(options::Dict{String, Any})
    printstyled("Raytracer.jl image rendering\n\n", bold=true)
    println("Number of threads: $(Threads.nthreads())")

    options["input-script"] = normpath(options["input-script"])
    options["output-file"] = normpath(options["output-file"])
    output_hdr_file = join([options["output-file"], "pfm"], ".")
    output_ldr_file = join([options["output-file"], options["ldr-extension"]], ".")

    cond1 = isfile(output_hdr_file)
    cond2 = options["with-tonemapping"] && isfile(output_ldr_file)
    if !options["force"] && (cond1 || cond2)
        img_str = cond1 ? cond2 ? output_hdr_file*"\" and \""*output_ldr_file : output_hdr_file : output_ldr_file
        printstyled("\nWarning!", bold=true, color=:yellow)
        print(" Image \"$(img_str)\" existing: overwrite? [y|n] ")
        if readline() != "y"
            printstyled("Aborting.\n", bold=true, color=:red)
            exit(1)
        end
    end

    Raytracer.render_from_script(
        options["input-script"],
        output_file = output_hdr_file,
        time = options["time"]
    )

    if options["with-tonemapping"]
        if options["luminosity"] == -1
            options["luminosity"] = nothing
        end
        Raytracer.tonemapping(
            output_hdr_file,
            output_ldr_file,
            α = options["alpha"],
            γ = options["gamma"],
            luminosity = (options["luminosity"])
        )
    end
end


function renderanimation_loop(elem::Tuple{Int, Float32}, total_elem::Int, options::Dict{String, Any})
    index, t = elem
    # create file name
    filename = joinpath(options["output-dir"], "$(options["output-file"])_$(lpad(repr(index), trunc(Int, log10(total_elem))+1, '0'))")
    output_hdr_file = "$(filename).pfm"
    output_ldr_file = "$(filename).$(options["ldr-extension"])"
    # render
    Raytracer.render_from_script(
        options["input-script"],
        output_file = output_hdr_file,
        time = t,
        use_threads = false,
        disable_output = true
    )
    # apply tonemapping
    if options["luminosity"] == -1
        options["luminosity"] = nothing
    end
    Raytracer.tonemapping(
        output_hdr_file,
        output_ldr_file,
        α = options["alpha"],
        γ = options["gamma"],
        luminosity = options["luminosity"],
        disable_output = true
    )
    # remove hdr image
    rm(output_hdr_file)
end

function renderanimation(options::Dict{String, Any})
    printstyled("Raytracer.jl animation rendering\n\n", bold=true)
    println("Number of threads: $(Threads.nthreads())\n")

    if Sys.which("ffmpeg") === nothing
        println()
        print_error("ffmpeg not found in PATH", "\n")
        exit(1)
    end

    options["input-script"] = normpath(options["input-script"])
    options["output-dir"] = normpath(options["output-dir"])
    options["output-file"] = normpath(options["output-file"])

    demodir = options["output-dir"]
    if !options["force"] && isdir(demodir)
        printstyled("Warning!", bold=true, color=:yellow)
        print(" Directory \"$(demodir)\" existing: overwrite content? [y|n] ")
        if readline() != "y"
            printstyled("Aborting.\n", bold=true, color=:red)
            exit(1)
        end
    end

    print("Creating directory \"$(options["output-dir"])\"...")
    rm(demodir, force=true, recursive=true)
    mkdir(demodir)
    println(" done!")

    println("\n-> RENDERING")
    t_start, t_end = Tuple(parse.(Float32, split(options["time-limits"], ":")))
    t_list = (if options["n-frames"] === nothing
        range(t_start, t_end, step=ifelse(t_start<t_end,1,-1)*options["delta-t"])
    else
        range(t_start, t_end, length=options["n-frames"]+1)
    end)[begin:end-1]
    l_t_list = length(t_list)
    println("Generating $(l_t_list) frames...")
    p = Progress(l_t_list, dt=2, color=:white)
    Threads.@threads for elem in collect(enumerate(t_list))
        renderanimation_loop(elem, l_t_list, options)
        next!(p)
    end

    println("\n-> CREATE ANIMATION")
    print("Generating animation...")
    padding = trunc(Int, log10(l_t_list)) + 1
    file_pattern = joinpath(options["output-dir"], "$(options["output-file"])_%0$(padding)d.$(options["ldr-extension"])")
    framerate = ["-r", options["fps"]]
    encoding_options = ["-c:v", "libx264", "-preset", "slow", "-vf", "format=yuv420p", "-movflags", "+faststart"]
    out_file = joinpath(options["output-dir"], "$(options["output-file"]).mp4")
    run(pipeline(
        `ffmpeg -y -i $(file_pattern) $(framerate) $(encoding_options) $(out_file)`,
        stdout=devnull,
        stderr=devnull
    ))
    println(" done!")
end


function tonemapping(options::Dict{String, Any})
    printstyled("Raytracer.jl tone mapping process\n", bold=true)
    # normalize path
    options["input-file"] = normpath(options["input-file"])
    options["output-file"] = normpath(options["output-file"])
    # check if output file exist
    if !options["force"] && isfile(options["output-file"])
        printstyled("\nWarning!", bold=true, color=:yellow)
        print(" Image \"$(options["output-file"])\" existing: overwrite? [y|n] ")
        if readline() != "y"
            printstyled("Aborting.\n", bold=true, color=:red)
            exit(1)
        end
    end
    # apply tonemapping
    if options["luminosity"] == -1
        options["luminosity"] = nothing
    end
    Raytracer.tonemapping(
        options["input-file"],
        options["output-file"],
        α = options["alpha"],
        γ = options["gamma"],
        luminosity = options["luminosity"]
    )
end


function docs(options::Dict{String, Any})
    doc_type = options["dev"] ? "dev" : "stable"
    printstyled("Raytracer.jl $(doc_type) documentation\n", bold=true)
    printstyled("\nDocumentation\n", bold=true)
    println("  - https://paolo97gll.github.io/Raytracer.jl/$(doc_type)")
    printstyled("\nCLI quickstart\n", bold=true)
    println("  - https://paolo97gll.github.io/Raytracer.jl/$(doc_type)/quickstart/cli")
    printstyled("\nSceneLang quickstart\n", bold=true)
    println("  - https://paolo97gll.github.io/Raytracer.jl/$(doc_type)/quickstart/scenelang")
    println()
end


#######
# main


function main()
    printstyled(raw"""
               _                            _ _    _ _
 _ _ __ _ _  _| |_ _ _ __ _ __ ___ _ _   __| (_)  (_) |
| '_/ _` | || |  _| '_/ _` / _/ -_) '_| / _| | |_ | | |
|_| \__,_|\_, |\__|_| \__,_\__\___|_| __\__|_|_(_)/ |_|
          |__/                       |__|       |__/

""", bold=true, color=:green)

    parsed_args = parse_commandline()

    parsed_command = parsed_args["%COMMAND%"]
    parsed_args = parsed_args[parsed_command]

    if parsed_command == "render"
        parsed_subcommand = parsed_args["%COMMAND%"]
        parsed_command *= parsed_subcommand
        parsed_args = parsed_args[parsed_subcommand]
    end

    printstyled("raytracer_cli.jl : ", bold=true)

    (Symbol(parsed_command) |> eval)(parsed_args)
end


main()
