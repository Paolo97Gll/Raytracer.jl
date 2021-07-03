# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Main parser file

let parser_dir = "parser"
    include(joinpath(parser_dir, "scene.jl"))
    include(joinpath(parser_dir, "utils.jl"))
    include(joinpath(parser_dir, "expectations.jl"))
    include(joinpath(parser_dir, "parse_constructors.jl"))
    include(joinpath(parser_dir, "parse_commands.jl"))
    include(joinpath(parser_dir, "parse_scene.jl"))
    include(joinpath(parser_dir, "cli_parsing.jl"))
end
