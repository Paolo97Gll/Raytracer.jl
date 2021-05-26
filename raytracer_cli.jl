#!/usr/bin/env julia

# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   raytracer_cli.jl
# description:
#   CLI tool for to manage through Raytracer.jl package
#   the generation and rendering of photorealistic images.


using Pkg
Pkg.activate(normpath(@__DIR__))

using ArgParse
using Raytracer
using ProgressMeter
using FileIO, ImageIO, ImageMagick, ImagePFM
using FileIO: File, @format_str, query


#####################################################


function parse_commandline_error_handler(settings::ArgParseSettings, err, err_code::Int = 1)
    if occursin("out of range input for input_file:", err.text)
        println(stderr, "input_file is not a PFM file")
    else
        println(stderr, err.text)
    end
    println(stderr, usage_string(settings))
    exit(err_code)
end


function parse_commandline()
    s = ArgParseSettings()
    s.description = "Raytracing for the generation of photorealistic images in Julia."
    s.exc_handler = parse_commandline_error_handler
    s.version = @project_version
    @add_arg_table! s begin
        "tonemapping"
            action = :command
            help = "apply tone mapping to a pfm image and save it to file"
        "demo"
            action = :command
            help = "show a demo of Raytracer.jl"
    end

    s["tonemapping"].description = "Apply tone mapping to a pfm image and save it to file."
    add_arg_group!(s["tonemapping"], "tonemapping settings");
    @add_arg_table! s["tonemapping"] begin
        "--alpha", "-a"
            help = "scaling factor for the normalization process"
            arg_type = Float64
            default = 0.5
        "--gamma", "-g"
            help = "gamma value for the tone mapping process"
            arg_type = Float64
            default = 1.
    end
    add_arg_group!(s["tonemapping"], "files");
    @add_arg_table! s["tonemapping"] begin
        "input_file"
            help = "path to input file, it must be a PFM file"
            range_tester = input -> (typeof(query(input))<:File{format"PFM"})
            required = true
        "output_file"
            help = "output file name"
            required = true
    end

    s["demo"].description = "Show a demo of Raytracer.jl."
    @add_arg_table! s["demo"] begin
        "image"
            action = :command
            help = "render a demo image of Raytracer.jl"
        "animation"
            action = :command
            help = "create a demo animation of Raytracer.jl (require ffmpeg)"
    end

    s["demo"]["image"].description = "Render a demo image of Raytracer.jl."
    add_arg_group!(s["demo"]["image"], "generation");
    @add_arg_table! s["demo"]["image"] begin
        "--camera_type", "-t"
            help = "choose camera type ('perspective' or 'orthogonal')"
            arg_type = String
            default = "perspective"
            range_tester = input -> (input ∈ ["perspective", "orthogonal"])
        "--camera_position", "-p"
            help = "camera position in the scene as 'X,Y,Z'"
            arg_type = String
            default = "-1,0,0"
            range_tester = input -> (length(split(input, ",")) == 3)
        "--camera_orientation", "-o"
            help = "camera orientation as 'angX,angY,angZ'"
            arg_type = String
            default = "0,0,0"
            range_tester = input -> (length(split(input, ",")) == 3)
        "--screen_distance", "-d"
            help = "only for 'perspective' camera: distance between camera and screen"
            arg_type = Float64
            default = 2.
    end
    add_arg_group!(s["demo"]["image"], "rendering");
    @add_arg_table! s["demo"]["image"] begin
        "--image_resolution", "-r"
            help = "resolution of the rendered image"
            arg_type = String
            default = "540:540"
        "--renderer", "-R"
            help = "type of renderer to use (`OnOff` or `Flat`)"
            arg_type = String
            default = "OnOff"
            range_tester = input -> (input ∈ ["OnOff", "Flat"])
    end
    add_arg_group!(s["demo"]["image"], "tonemapping");
    @add_arg_table! s["demo"]["image"] begin
        "--alpha", "-a"
            help = "scaling factor for the normalization process"
            arg_type = Float64
            default = 1.
        "--gamma", "-g"
            help = "gamma value for the tone mapping process"
            arg_type = Float64
            default = 1.
    end
    add_arg_group!(s["demo"]["image"], "files");
    @add_arg_table! s["demo"]["image"] begin
        "--output_file", "-O"
            help = "output LDR file name (the HDR file will have the same name, but with 'pfm' extension)"
            arg_type = String
            default = "demo.jpg"
    end

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
            help = "choose camera type ('perspective' or 'orthogonal')"
            arg_type = String
            default = "perspective"
            range_tester = input -> (input ∈ ["perspective", "orthogonal"])
        "--camera_position", "-p"
            help = "camera position in the scene as 'X,Y,Z'"
            arg_type = String
            default = "-1,0,0"
            range_tester = input -> (length(split(input, ",")) == 3)
        "--screen_distance", "-d"
            help = "only for 'perspective' camera: distance between camera and screen"
            arg_type = Float64
            default = 2.
    end
    add_arg_group!(s["demo"]["animation"], "frame rendering");
    @add_arg_table! s["demo"]["animation"] begin
        "--image_resolution", "-r"
            help = "resolution of the rendered image"
            arg_type = String
            default = "540:540"
        "--renderer", "-R"
            help = "type of renderer to use (`OnOff` or `Flat`)"
            arg_type = String
            default = "OnOff"
            range_tester = input -> (input ∈ ["OnOff", "Flat"])
    end
    add_arg_group!(s["demo"]["animation"], "frame tonemapping");
    @add_arg_table! s["demo"]["animation"] begin
        "--alpha", "-a"
            help = "scaling factor for the normalization process"
            arg_type = Float64
            default = 1.
        "--gamma", "-g"
            help = "gamma value for the tone mapping process"
            arg_type = Float64
            default = 1.
    end
    add_arg_group!(s["demo"]["animation"], "animation parameter");
    @add_arg_table! s["demo"]["animation"] begin
        "--delta_theta", "-D"
            help = "Δθ in camera orientation (around z axis) between each frame; the number of frames generated is [360/Δθ]"
            arg_type = Int64
            default = 10
        "--fps", "-f"
            help = "FPS (frame-per-second) of the output video"
            arg_type = Int64
            default = 15
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


#####################################################


function tonemapping(options::Dict{String, Any})
    Raytracer.tonemapping(
        options["input_file"],
        options["output_file"],
        options["alpha"],
        options["gamma"]
    )
end


function demoimage(options::Dict{String, Any})
    Raytracer.demo(
        options["output_file"],
        Tuple(parse.(Int64, split(options["image_resolution"], ":"))),
        options["camera_type"],
        Tuple(parse.(Float64, split(options["camera_position"], ","))),
        Tuple(parse.(Float64, split(options["camera_orientation"], ","))),
        options["screen_distance"],
        Symbol(options["renderer"], "Renderer") |> eval,
        options["alpha"],
        options["gamma"]
    )
end


function demoanimation(options::Dict{String, Any})
    println("\n-------------------------------")
    println("| Raytracer.jl animation demo |")
    println("-------------------------------")
    println("Threads number: $(Threads.nthreads())\n")

    curdir = pwd()
    demodir = options["output_dir"]
    if !options["force"] && isdir(joinpath(curdir, demodir))
        print("Directory ./$(demodir)/ existing: overwrite content? [y|n] ")
        if readline() != "y"
            println("Aborting.")
            return 1
        end
        println()
    end

    print("Creating directory ./$(options["output_dir"])/...")
    isdir(joinpath(curdir, demodir)) || mkdir(demodir)
    cd(demodir)
    println(" done!")

    θ_list = (0:options["delta_theta"]:360)[begin:end-1]
    println("Generating $(length(θ_list)) frames...")
    p = Progress(length(θ_list), dt=1)
    Threads.@threads for elem in collect(enumerate(θ_list))
        index, θ = elem
        filename = "$(options["output_file"])_$(lpad(repr(index), trunc(Int, log10(length(θ_list)))+1, '0'))"
        Raytracer.demo(
            filename * ".jpg",
            Tuple(parse.(Int64, split(options["image_resolution"], ":"))),
            options["camera_type"],
            Tuple(parse.(Float64, split(options["camera_position"], ","))),
            (0, 0, θ),
            options["screen_distance"],
            Symbol(options["renderer"], "Renderer") |> eval,
            options["alpha"],
            options["gamma"],
            disable_output=true
        )
        rm(filename * ".pfm")
        next!(p)
    end
    
    print("Generating animation...")
    run(pipeline(`ffmpeg -y -r $(options["fps"]) -pattern_type glob -i "$(options["output_file"])_*.jpg" -c:v libx264 $(options["output_file"]).mp4`, stdout=devnull, stderr=devnull))
    println(" done!")

    cd(curdir)
end


#####################################################


function main()
    parsed_args = parse_commandline()

    parsed_command = parsed_args["%COMMAND%"]
    parsed_args = parsed_args[parsed_command]

    if parsed_command == "demo"
        parsed_subcommand = parsed_args["%COMMAND%"]
        parsed_command *= parsed_subcommand
        parsed_args = parsed_args[parsed_subcommand]
    end

    (Symbol(parsed_command) |> eval)(parsed_args)
end


main()