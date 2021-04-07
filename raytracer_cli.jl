#!/usr/bin/env julia


using Pkg
Pkg.activate(normpath(@__DIR__))

using ArgParse
using Raytracer
using Suppressor
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
    s = ArgParseSettings(
        description = "Raytracing for the generation of photorealistic images in Julia.",
        exc_handler = parse_commandline_error_handler,
        version = @project_version
    )

    @add_arg_table! s begin
        "generate"
            action = :command
            help = "generate from input"
        "tonemapping"
            action = :command
            help = "exec tone mapping of a pfm image and save it to file"
    end

    # debug_dict = Dict(
    #     :nargs => '?',
    #     :help => "Enable more detailed informations. If LOGFILE filename is specified, debugging output is redirected to LOGFILE",
    #     :arg_type => String,
    #     :constant => "",
    #     :metavar => "LOGFILE"
    # )
    # add_arg_table!(s["generate"], ["--debug", "-d"], debug_dict)
    # add_arg_table!(s["tonemapping"], ["--debug", "-d"], debug_dict)

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

    # if parsed_args["debug"] !== nothing
    #     println()
    #     if parsed_args["debug"] == ""
    #         println("Debug on console")
    #     else
    #         println("Debug file: '$(parsed_args["debug"])'")
    #         if isfile(parsed_args["debug"])
    #             print("File already existing, overwrite? [y|n] ")
    #             answer = readline()
    #             if answer != "y"
    #                 println("Aborting.")
    #                 return
    #             end
    #         end
    #         open(parsed_args["debug"], "w") do io
    #         end
    #     end
    # end
    
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
