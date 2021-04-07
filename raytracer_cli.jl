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

    debug_dict = Dict(
        :nargs => '?',
        :help => "Enable more detailed informations. If LOGFILE filename is specified, debugging output is redirected to LOGFILE",
        :arg_type => String,
        :constant => "",
        :metavar => "LOGFILE"
    )
    add_arg_table!(s["generate"], ["--debug", "-d"], debug_dict)
    add_arg_table!(s["tonemapping"], ["--debug", "-d"], debug_dict)

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
    
    # generate
    if parsed_args["%COMMAND%"] == "generate"
        println("Not yet implemented.")

    # tonemapping
    elseif parsed_args["%COMMAND%"] == "tonemapping"
        parsed_args = parsed_args["tonemapping"]
        try
            image = load(parsed_args["input_file"]) |> HdrImage
            image = normalize_image(image, parsed_args["alpha"]) |> clamp_image
            image = γ_correction(image, parsed_args["gamma"])
            save_output = @capture_out begin
                save(parsed_args["output_file"], image.pixel_matrix)
            end
            if parsed_args["debug"] !== nothing
                if parsed_args == ""
                    println(stderr, save_output)
                else
                    open(parsed_args["debug"]) do io
                        println(io, save_output)
                    end
                end
            end
        catch e
            println("Something went wrong.")
            if parsed_args["debug"] !== nothing
                if parsed_args == ""
                    showerror(stderr, e)
                else
                    open(parsed_args["debug"]) do io
                        showerror(io, e)
                    end
                end
            end
        end

    end
end


main()
