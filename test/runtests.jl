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

@testset "Camera" begin
    include("test_cameras.jl")
end

@testset "ImageTracer" begin
    include("test_image_tracer.jl")
end

@testset "Shape" begin
    include("test_shape.jl")
end

@testset "Docs" begin
    doctest(Raytracer, manual=false)
end