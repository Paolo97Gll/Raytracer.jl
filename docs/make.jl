# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Generate documentation


push!(LOAD_PATH, "../src/")


using Pkg
Pkg.activate(normpath(@__DIR__))
# Pkg.activate(normpath(joinpath(@__DIR__, "..")))

using Documenter

using Raytracer
using Raytracer:
    SimpleShape, CompositeShape


makedocs(
    sitename = "Raytracer.jl",
    pages = [
        "Introduction" => "index.md",
        "Quickstart" => [
            "Basic CLI usage" => "quickstart/cli.md",
            "Basic SceneLang usage" => "quickstart/scenelang.md",
            "Basic API usage" => "quickstart/api.md"
        ],
        "SceneLang" => "scenelang.md",
        "CLI tool" => "cli.md",
        "API" => [
            "High-level API" => "api/high-level.md",
            "Low-level API" => "api/low-level.md"
        ],
        "Extendability" => "extendability.md",
        "For devs" => [
            "Collaboration instructions" => "devs/collab.md",
            "Private API" => "devs/private-api.md",
            "SceneLang interpreter API" => "devs/scenelang-api.md"
        ]
    ]
)

deploydocs(
    repo = "github.com/Paolo97Gll/Raytracer.jl.git",
    push_preview = true
)
