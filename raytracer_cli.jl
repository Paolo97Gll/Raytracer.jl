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

    s["demo"].description = "Show a demo of Raytracer.jl."
    add_arg_group!(s["demo"], "generation");
    @add_arg_table! s["demo"] begin
        "--camera_type", "-t"
            help = "choose camera type ('perspective' or 'orthogonal')"
            arg_type = String
            default = "perspective"
            range_tester = input -> (input ∈ ["perspective", "orthogonal"])
        "--camera_position", "-p"
            help = "camera position in the scene"
            arg_type = String
            default = "-1,0,0"
            range_tester = input -> (length(split(input, ",")) == 3)
        "--camera_orientation", "-o"
            help = "camera orientation"
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
            help = "output file name"
            arg_type = String
            default = "demo.jpg"
    end
    
    parse_args(s)
end


function tonemapping(options)
    println("\n--------------------")
    println("TONE MAPPING PROCESS\n")
    println("Loading input file '$(options["input_file"])'...")
    image = load(options["input_file"]) |> HdrImage
    println("Applying tone mapping...")
    image = normalize_image(image, options["alpha"]) |> clamp_image
    image = γ_correction(image, options["gamma"])
    println("Saving final image to '$(options["output_file"])'...")
    save(options["output_file"], image.pixel_matrix)
    println("Done!")
end
    
function demo(options)
    println("\n--------------------")
    println("RAYTRACER DEMO\n")
    println("--------------------")
    println("RENDERING\n")
    println("Loading ambient...")
    world = World(undef, 10)
    for (i, coords) ∈ enumerate(map(i -> map(bit -> Bool(bit) ? 1 : -1 , digits(i, base=2, pad=3)) |> collect, 0x00:(0x02^3-0x01)))
        world[i] = Sphere(translation(coords * 0.5) * scaling(1/10))
    end
    world[end-1:end] = [Sphere(translation([0, 0, -0.5]) * scaling(1/10)), Sphere(translation([0, 0.5, 0]) * scaling(1/10))]
    # display(getfield.(world, :transformation) .* Ref(Point(0,0,0)))
    # img = HdrImage(1920, 1080)
    println("Generating image...")
    img_size = parse.(Int64, split(options["image_resolution"], ":"))
    img = HdrImage{RGB{Float64}}(img_size...)
    camera_position = "["*options["camera_position"]*"]" |> Meta.parse |> eval
    # camera_orientation = "["*options["camera_orientation"]*"]" |> Meta.parse |> eval
    angx, angy, angz = deg2rad.(parse.(Float64, split(options["camera_orientation"], ",")))
    rot = rotationX(angx)*rotationY(angy)*rotationZ(angz)
    if options["camera_type"] == "perspective"
        camera = PerspectiveCamera(//(img_size...), translation(camera_position)*rot, options["screen_distance"])
    else
        camera = OrthogonalCamera(//(img_size...), translation(camera_position)*rot)
    end
    image_tracer = ImageTracer(img, camera)
    @time fire_all_rays(image_tracer, ray -> any(shape -> ray_intersection(ray, shape) !== nothing, world) ? RGB(1.,1.,1.) : RGB(0.,0.,0.))
    println("Saving pfm image...")
    options["input_file"] = join([split(options["output_file"], ".")[begin:end-1]..., "pfm"], ".")
    save(options["input_file"], permutedims(img.pixel_matrix))
    println("Done!")
    tonemapping(options)
end


function main()
    parsed_args = parse_commandline()
    parsed_command = parsed_args["%COMMAND%"]
    parsed_args = parsed_args[parsed_command]
    (Symbol(parsed_command) |> eval)(parsed_args)
end


main()