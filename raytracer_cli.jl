#!/usr/bin/env julia


using Pkg
Pkg.activate(normpath(@__DIR__))

using ArgParse
using Raytracer
import FileIO: File, @format_str, query


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
        "generate"
            action = :command
            help = "generate photorealistic image from input file"
        "tonemapping"
            action = :command
            help = "apply tone mapping to a pfm image and save it to file"
    end

    s["generate"].description = "Generate photorealistic image from input file."

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
    
    parse_args(s)
end


function main()
    parsed_args = parse_commandline()
    parsed_command = parsed_args["%COMMAND%"]
    parsed_args = parsed_args[parsed_command]
    
    # generate
    if parsed_command == "generate"
        println("\n-----------------------------")
        println("GENERATE PHOTOREALISTIC IMAGE\n")
        println("Not yet implemented.")

    # tonemapping
    elseif parsed_command == "tonemapping"
        println("\n--------------------")
        println("TONE MAPPING PROCESS\n")
        println("Loading input file '$(parsed_args["input_file"])'...")
        image = load(parsed_args["input_file"]) |> HdrImage
        println("Applying tone mapping...")
        image = normalize_image(image, parsed_args["alpha"]) |> clamp_image
        image = γ_correction(image, parsed_args["gamma"])
        println("Saving final image to '$(parsed_args["output_file"])'...")
        save(parsed_args["output_file"], image.pixel_matrix)
        println("Done!")
    end
end


main()
