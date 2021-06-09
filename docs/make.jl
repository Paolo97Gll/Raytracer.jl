# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Generate documentation

using Pkg
Pkg.activate(normpath((@__DIR__) * "/.."))

using Raytracer

using Documenter


################
# Generate docs


makedocs(
    sitename="Raytracer.jl"
)
