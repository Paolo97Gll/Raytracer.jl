# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   runtests.jl
# description:
#   Main package test file.


using Raytracer
using StaticArrays, LinearAlgebra
using Test, Documenter
import Raytracer:
    _clamp, luminosity, average_luminosity, _γ_correction,
    norm², VEC_X, VEC_Y, VEC_Z

DocMeta.setdocmeta!(Raytracer, :DocTestSetup, :(using Raytracer); recursive=true)

@testset "Color" begin
    include("test_color.jl")
end

@testset "HDR Image" begin
    include("test_hdr_image.jl")
end

@testset "Geometry" begin
    include("test_geometry.jl")
end

@testset "Ray" begin
    include("test_ray.jl")
end

# TODO implement tests for `cameras.jl` and `image_tracer.jl`

@testset "Docs" begin
    doctest(Raytracer, manual=false)
end