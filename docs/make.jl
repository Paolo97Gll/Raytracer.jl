# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Generate documentation


push!(LOAD_PATH,"../src/")


using Pkg
Pkg.activate(normpath(@__DIR__))

using Documenter, Raytracer


makedocs(
    sitename = "Raytracer.jl",
    pages = [
        "Introduction" => "index.md",
        "Quickstart" => [
            "Basic ScieneLang usage" => "quickstart/scienelang.md",
            "Basic CLI usage" => "quickstart/cli.md",
            "Basic API usage" => "quickstart/api.md"
        ],
        "ScieneLang" => "scienelang.md",
        "CLI tool" => "cli.md",
        "API" => [
            "High level" => "api/high-level.md",
            "Low level" => "api/low-level.md"
        ],
        "For devs" => [
            "Collaboration instructions" => "devs/collab.md",
            "Private documentation" => "devs/private-docs.md"
        ]
    ]
)

deploydocs(
    repo = "github.com/Paolo97Gll/Raytracer.jl.git"
)
