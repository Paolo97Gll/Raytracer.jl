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
    
    parse_args(s)
end


function main()
    parsed_args = parse_commandline()
    parsed_command = parsed_args["%COMMAND%"]
    parsed_args = parsed_args[parsed_command]
    
    # # generate
    # if parsed_command == "generate"
    #     println("\n-----------------------------")
    #     println("GENERATE PHOTOREALISTIC IMAGE\n")
    #     println("Not yet implemented.")

    # tonemapping
    if parsed_command == "tonemapping"
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
        return
    end

    if parsed_command == "demo"
        world = World(undef, 10)
        for (i, coords) ∈ enumerate(map(i -> map(bit -> Bool(bit) ? 1 : -1 , digits(i, base=2, pad=3)) |> collect, 0x00:(0x02^3-0x01)))
            world[i] = Sphere(translation(coords * 0.5) * scaling(1/10))
        end
        world[end-1:end] = [Sphere(translation([0, 0, -0.5]) * scaling(1/10)), Sphere(translation([0, 0.5, 0]) * scaling(1/10))]
        # display(getfield.(world, :transformation) .* Ref(Point(0,0,0)))
        # img = HdrImage(1920, 1080)
        img = HdrImage(1080÷2, 1080÷2)
        image_tracer = ImageTracer(img, PerspectiveCamera(//(size(img)...), translation(-1.5, 0, 0), 1.5))
        println("Tracing Image")
        @time fire_all_rays(image_tracer, ray -> any(shape -> ray_intersection(ray, shape) !== nothing, world) ? RGB(1.,1.,1.) : RGB(0.,0.,0.))
        save("demo.jpg", permutedims(img.pixel_matrix))
        println("Done!")
        return
    end
end


main()
