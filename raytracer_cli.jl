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
        # "generate"
        #     action = :command
        #     help = "generate photorealistic image from input file"
        "tonemapping"
            action = :command
            help = "apply tone mapping to a pfm image and save it to file"
        "demo"
            action = :command
            help = "show a demo of Raytracer.jl"
    end

    # s["generate"].description = "Generate photorealistic image from input file."

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
    add_arg_group!(s["demo"], "generation");
    @add_arg_table! s["demo"] begin
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
            default = 1.
    end
    add_arg_group!(s["demo"], "rendering");
    @add_arg_table! s["demo"] begin
        "--image_resolution", "-r"
            help = "resolution of the rendered image"
            arg_type = String
            default = "540:540"
        "--renderer"
            help = "type of renderer to use (`OnOff` or `Flat`)"
            arg_type = String
            default = "OnOff"
            range_tester = input -> (input ∈ ["OnOff", "Flat"])
    end
    add_arg_group!(s["demo"], "tonemapping");
    @add_arg_table! s["demo"] begin
        "--alpha", "-a"
            help = "scaling factor for the normalization process"
            arg_type = Float64
            default = 1.
        "--gamma", "-g"
            help = "gamma value for the tone mapping process"
            arg_type = Float64
            default = 1.
    end
    add_arg_group!(s["demo"], "files");
    @add_arg_table! s["demo"] begin
        "--output_file"
            help = "output LDR file name (the HDR file will have the same name, but with 'pfm' extension)"
            arg_type = String
            default = "demo.jpg"
    end
    
    parse_args(s)
end


#####################################################


function tonemapping(options::AbstractDict{String, Any})
    tonemapping(options["input_file"], options["output_file"], options["alpha"], options["gamma"])
end


function demo(options::AbstractDict{String, Any})
    renderer_type = Symbol(options["renderer"], "Renderer") |> eval
    Raytracer.demo(options["output_file"],
                   Tuple(parse.(Int64, split(options["image_resolution"], ":"))),
                   options["camera_type"],
                   Tuple(parse.(Float64, split(options["camera_position"], ","))),
                   Tuple(parse.(Float64, split(options["camera_orientation"], ","))),
                   options["screen_distance"],
                   renderer_type,
                   options["alpha"],
                   options["gamma"])
end


#####################################################


function main()
    parsed_args = parse_commandline()
    parsed_command = parsed_args["%COMMAND%"]
    parsed_args = parsed_args[parsed_command]
    (Symbol(parsed_command) |> eval)(parsed_args)
end


main()