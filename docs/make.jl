# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Generate documentation

using Pkg
Pkg.activate(normpath(@__DIR__))

using Documenter, Raytracer


makedocs(
    sitename = "Raytracer.jl"
)

deploydocs(
    repo = "github.com/Paolo97Gll/Raytracer.jl.git",
)
