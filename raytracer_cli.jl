#!/usr/bin/env julia

# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# CLI tool for to manage through Raytracer.jl package the generation
# and rendering of photorealistic images


using Pkg
Pkg.activate(normpath(@__DIR__))

using Raytracer

using ArgParse, ImageIO, ImageMagick, ImagePFM, ProgressMeter
using FileIO:
    File, @format_str, query


###########
# ArgParse


function parse_commandline_error_handler(settings::ArgParseSettings, err, err_code::Int = 1)
    s = reduce(replace, ["out of range input for " => "", " " => ""], init=err.text)
    parameter, value = split(s, ":")

    println()

    if parameter == "input_file"
        @error "the parameter $(parameter) (\"$(value)\") must be a PFM file"
    elseif parameter ∈ ["--alpha", "-a", "--gamma", "-g", "--screen_distance", "-d", "--pt_n", "--pt_max_depth", "--pt_roulette_depth", "--fps", "-f"]
        @error "the parameter $(parameter) (\"$(value)\") must be > 0"
    elseif parameter ∈ ["--camera_type", "-t"]
        @error "the parameter $(parameter) (\"$(value)\") must be \"perspective\" or \"orthogonal\""
    elseif parameter ∈ ["--camera_position", "-p", "--camera_orientation", "-o"]
        @error "the parameter $(parameter) (\"$(value)\") must be composed of 3 Float32 values divided by a ',' (e.g., \"-3,0,0\")"
    elseif parameter ∈ ["--image_resolution", "-r"]
        @error "the parameter $(parameter) (\"$(value)\") must be composed of 2 positive Int values divided by a ':' (e.g., \"540:540\")"
    elseif parameter ∈ ["--renderer", "-R"]
        @error "the parameter $(parameter) (\"$(value)\") must be \"onoff\", \"flat\" or \"path\""
    elseif parameter ∈ ["--antialiasing", "-A"]
        @error "the parameter $(parameter) (\"$(value)\") must be a perfect square (e.g., 4, 9 or 16)"
    elseif parameter ∈ ["--delta_theta", "-D"]
        @error "the parameter $(parameter) (\"$(value)\") must be > 0 and < 360"
    else
        @error err.text
    end

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
        "tonemapping"
            action = :command
            help = "apply tone mapping to a pfm image and save it to file"
        "demo"
            action = :command
            help = "show a demo of Raytracer.jl"
    end

    # tonemapping

    s["tonemapping"].description = "Apply tone mapping to a pfm image and save it to file."
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
    end
    add_arg_group!(s["tonemapping"], "files");
    @add_arg_table! s["tonemapping"] begin
        "input_file"
            help = "path to input file, it must be a PFM file"
            range_tester = x -> typeof(query(x))<:File{format"PFM"}
            required = true
        "output_file"
            help = "output file name"
            required = true
    end

    # demo

    s["demo"].description = "Show a demo of Raytracer.jl."
    @add_arg_table! s["demo"] begin
        "image"
            action = :command
            help = "render a demo image of Raytracer.jl"
        "animation"
            action = :command
            help = "create a demo animation of Raytracer.jl (require ffmpeg)"
    end

    # demo image

    s["demo"]["image"].description = "Render a demo image of Raytracer.jl."
    @add_arg_table! s["demo"]["image"] begin
        "--force"
            help = "force overwrite"
            action = :store_true
    end
    add_arg_group!(s["demo"]["image"], "camera");
    @add_arg_table! s["demo"]["image"] begin
        "--camera_type", "-t"
            help = "choose camera type (\"perspective\" or \"orthogonal\")"
            arg_type = String
            default = "perspective"
            range_tester = x -> x ∈ ["perspective", "orthogonal"]
        "--camera_position", "-p"
            help = "camera position in the scene as \"X,Y,Z\""
            arg_type = String
            default = "-3,0,0"
            range_tester = x -> length(Tuple(parse.(Float32, split(x, ",")))) == 3
        "--camera_orientation", "-o"
            help = "camera orientation as \"angX,angY,angZ\""
            arg_type = String
            default = "0,0,0"
            range_tester = x -> length(Tuple(parse.(Float32, split(x, ",")))) == 3
        "--screen_distance", "-d"
            help = "only for \"perspective\" camera: distance between camera and screen"
            arg_type = Float32
            default = 2f0
            range_tester = x -> x > 0
    end
    add_arg_group!(s["demo"]["image"], "rendering");
    @add_arg_table! s["demo"]["image"] begin
        "--image_resolution", "-r"
            help = "resolution of the rendered image"
            arg_type = String
            default = "540:540"
            range_tester = x -> length(Tuple(parse.(Int, split(x, ":")))) == 2
        "--renderer", "-R"
            help = "type of renderer to use (\"onoff\", \"flat\" or \"path\")"
            arg_type = String
            default = "path"
            range_tester = x -> (x ∈ ["onoff", "flat", "path"])
        "--antialiasing", "-A"
            help = "number of samples per pixel (must be a perfect square)"
            arg_type = Int
            default = 0
            range_tester = x -> isqrt(x)^2 == x
    end
    add_arg_group!(s["demo"]["image"], "path-tracer options (only for \"path\" renderer)");
    @add_arg_table! s["demo"]["image"] begin
        "--pt_n"
            help = "number of rays fired for mc integration"
            arg_type = Int
            default = 10
            range_tester = x -> x > 0
        "--pt_max_depth"
            help = "maximum number of reflections for each ray"
            arg_type = Int
            default = 2
            range_tester = x -> x > 0
        "--pt_roulette_depth"
            help = "depth of the russian-roulette algorithm"
            arg_type = Int
            default = 3
            range_tester = x -> x > 0
    end
    add_arg_group!(s["demo"]["image"], "tonemapping");
    @add_arg_table! s["demo"]["image"] begin
        "--alpha", "-a"
            help = "scaling factor for the normalization process"
            arg_type = Float32
            default = 0.75f0
            range_tester = x -> x > 0
        "--gamma", "-g"
            help = "gamma value for the tone mapping process"
            arg_type = Float32
            default = 1f0
            range_tester = x -> x > 0
    end
    add_arg_group!(s["demo"]["image"], "files");
    @add_arg_table! s["demo"]["image"] begin
        "--output_file", "-O"
            help = "output LDR file name (the HDR file will have the same name, but with \"pfm\" extension)"
            arg_type = String
            default = "demo.jpg"
    end

    # demo animation

    s["demo"]["animation"].description =
        "Create a demo animation of Raytracer.jl, by generating n images with different camera " *
        "orientation and merging them into an mp4 video. Require ffmpeg installed on local machine."
    @add_arg_table! s["demo"]["animation"] begin
        "--force"
            help = "force overwrite"
            action = :store_true
    end
    add_arg_group!(s["demo"]["animation"], "frame generation");
    @add_arg_table! s["demo"]["animation"] begin
        "--camera_type", "-t"
            help = "choose camera type (\"perspective\" or \"orthogonal\")"
            arg_type = String
            default = "perspective"
            range_tester = x -> x ∈ ["perspective", "orthogonal"]
        "--camera_position", "-p"
            help = "camera position in the scene as \"X,Y,Z\""
            arg_type = String
            default = "-3,0,0"
            range_tester = x -> length(Tuple(parse.(Float32, split(x, ",")))) == 3
        "--screen_distance", "-d"
            help = "only for \"perspective\" camera: distance between camera and screen"
            arg_type = Float32
            default = 2f0
            range_tester = x -> x > 0
    end
    add_arg_group!(s["demo"]["animation"], "frame rendering");
    @add_arg_table! s["demo"]["animation"] begin
        "--image_resolution", "-r"
            help = "resolution of the rendered image"
            arg_type = String
            default = "540:540"
            range_tester = x -> length(Tuple(parse.(Int, split(x, ":")))) == 2
        "--renderer", "-R"
            help = "type of renderer to use (\"onoff\", \"flat\" or \"path\")"
            arg_type = String
            default = "path"
            range_tester = x -> (x ∈ ["onoff", "flat", "path"])
        "--antialiasing", "-A"
            help = "number of samples per pixel (must be a perfect square)"
            arg_type = Int
            default = 0
            range_tester = x -> isqrt(x)^2 == x
    end
    add_arg_group!(s["demo"]["animation"], "path-tracer options (only for \"path\" renderer)");
    @add_arg_table! s["demo"]["animation"] begin
        "--pt_n"
            help = "number of rays fired for mc integration"
            arg_type = Int
            default = 10
            range_tester = x -> x > 0
        "--pt_max_depth"
            help = "maximum number of reflections for each ray"
            arg_type = Int
            default = 2
            range_tester = x -> x > 0
        "--pt_roulette_depth"
            help = "depth of the russian-roulette algorithm"
            arg_type = Int
            default = 3
            range_tester = x -> x > 0
    end
    add_arg_group!(s["demo"]["animation"], "frame tonemapping");
    @add_arg_table! s["demo"]["animation"] begin
        "--alpha", "-a"
            help = "scaling factor for the normalization process"
            arg_type = Float32
            default = 0.75f0
            range_tester = x -> x > 0
        "--gamma", "-g"
            help = "gamma value for the tone mapping process"
            arg_type = Float32
            default = 1f0
            range_tester = x -> x > 0
    end
    add_arg_group!(s["demo"]["animation"], "animation parameter");
    @add_arg_table! s["demo"]["animation"] begin
        "--delta_theta", "-D"
            help = "Δθ in camera orientation (around z axis) between each frame; the number of frames generated is [360/Δθ]"
            arg_type = Float32
            default = 10f0
            range_tester = x -> 0 < x < 360
        "--fps", "-f"
            help = "FPS (frame-per-second) of the output video"
            arg_type = Int
            default = 15
            range_tester = x -> x > 0
    end
    add_arg_group!(s["demo"]["animation"], "files");
    @add_arg_table! s["demo"]["animation"] begin
        "--output_dir", "-F"
            help = "output directory"
            arg_type = String
            default = "demo_animation"
        "--output_file", "-O"
            help = "name of output frames and animation without extension"
            arg_type = String
            default = "demo"
    end
    
    parse_args(s)
end


####################
# Utility functions


function tonemapping(options::Dict{String, Any})
    printstyled("apply tone mapping to a pfm image\n", bold=true)
    options["input_file"] = normpath(options["input_file"])
    options["output_file"] = normpath(options["output_file"])
    Raytracer.tonemapping(
        options["input_file"],
        options["output_file"],
        options["alpha"],
        options["gamma"]
    )
end


function demoimage(options::Dict{String, Any})
    printstyled("Raytracer.jl demo image\n\n", bold=true)
    println("Renderer: $(options["renderer"])")
    println("Number of threads: $(Threads.nthreads())\n")

    options["output_file"] = normpath(options["output_file"])

    if !options["force"] && isfile(options["output_file"])
        print("Image ./$(options["output_file"]) existing: overwrite? [y|n] ")
        if readline() != "y"
            println("Aborting.")
            exit(1)
        end
    end
    
    Raytracer.demo(
        output_file = options["output_file"],
        camera_type = options["camera_type"],
        camera_position = Tuple(parse.(Float32, split(options["camera_position"], ","))),
        camera_orientation = Tuple(parse.(Float32, split(options["camera_orientation"], ","))),
        screen_distance = options["screen_distance"],
        image_resolution = Tuple(parse.(Int, split(options["image_resolution"], ":"))),
        renderer_type = options["renderer"],
        samples_per_side = isqrt(options["antialiasing"]),
        pt_n = options["pt_n"],
        pt_max_depth = options["pt_max_depth"],
        pt_roulette_depth = options["pt_roulette_depth"],
        α = options["alpha"],
        γ = options["gamma"]
    )
end

function demoanimation_loop(elem::Tuple{Int, Float32}, total_elem::Int, options::Dict{String, Any})
    index, θ = elem
    filename = "$(options["output_file"])_$(lpad(repr(index), trunc(Int, log10(total_elem))+1, '0'))"
    Raytracer.demo(
        output_file = filename * ".jpg",
        camera_type = options["camera_type"],
        camera_position = Tuple(parse.(Float32, split(options["camera_position"], ","))),
        camera_orientation = (0f0, 0f0, θ),
        screen_distance = options["screen_distance"],
        image_resolution = Tuple(parse.(Int, split(options["image_resolution"], ":"))),
        renderer_type = options["renderer"],
        samples_per_side = isqrt(options["antialiasing"]),
        pt_n = options["pt_n"],
        pt_max_depth = options["pt_max_depth"],
        pt_roulette_depth = options["pt_roulette_depth"],
        α = options["alpha"],
        γ = options["gamma"],
        use_threads = false,
        disable_output = true
    )
    rm(filename * ".pfm")
end

function demoanimation(options::Dict{String, Any})
    printstyled("Raytracer.jl demo animation\n\n", bold=true)
    println("Renderer: $(options["renderer"])")
    println("Number of threads: $(Threads.nthreads())\n")

    if Sys.which("ffmpeg") === nothing
        println("ffmpeg not found. Aborting.")
        exit(1)
    end

    options["output_dir"] = normpath(options["output_dir"])
    options["output_file"] = normpath(options["output_file"])

    curdir = pwd()
    demodir = options["output_dir"]
    if !options["force"] && isdir(demodir)
        print("Directory ./$(demodir) existing: overwrite content? [y|n] ")
        if readline() != "y"
            println("Aborting.")
            exit(1)
        end
        println()
    end

    print("Creating directory ./$(options["output_dir"])...")
    rm(demodir, force=true, recursive=true)
    mkdir(demodir)
    cd(demodir)
    println(" done!")

    θ_list = (0f0:options["delta_theta"]:360f0)[begin:end-1]
    println("Generating $(length(θ_list)) frames...")
    p = Progress(length(θ_list), dt=2, color=:white)
    Threads.@threads for elem in collect(enumerate(θ_list))
        demoanimation_loop(elem, length(θ_list), options)
        next!(p)
    end
    
    print("Generating animation...")
    padding = trunc(Int, log10(length(θ_list))) + 1
    run(pipeline(
        `ffmpeg -y -framerate $(options["fps"]) -i demo_%0$(padding)d.jpg -c:v libx264 -preset slow -tune animation -vf format=yuv420p -movflags +faststart $(options["output_file"]).mp4`,
        stdout=devnull,
        stderr=devnull
    ))
    println(" done!")

    cd(curdir)
end


###########
# Parsers


function parse_item(::Type{Camera}, x::AbstractString)
    if x == "perspective"
        return PerspectiveCamera
    elseif x == "orthogonal"
        return OrthogonalCamera
    else
        error("No parsing is available from string \"$x\" to any subtype of `Camera`.")
    end
end

function parse_item(::Type{Renderer}, x::AbstractString)
    if x == "onoff"
        return OnOffRenderer
    elseif x == "flat"
        return FlatRenderer
    elseif x == "path"
        return PathTracer
    else
        error("No parsing is available from string \"$x\" to any subtype of `Renderer`.")
    end
end


#######
# main


function main()
    parsed_args = parse_commandline()

    parsed_command = parsed_args["%COMMAND%"]
    parsed_args = parsed_args[parsed_command]

    if parsed_command == "demo"
        parsed_subcommand = parsed_args["%COMMAND%"]
        parsed_command *= parsed_subcommand
        parsed_args = parsed_args[parsed_subcommand]
    end

    k = keys(parsed_args)
    for (parsable, parse_type) ∈ ["camera_type" => Camera, "renderer" => Renderer]
        parsable ∈ k && (parsed_args[parsable] = parse_item(parse_type, parsed_args[parsable]))
    end

    printstyled("\nraytracer_cli.jl : ", bold=true)

    (Symbol(parsed_command) |> eval)(parsed_args)
end


main()
