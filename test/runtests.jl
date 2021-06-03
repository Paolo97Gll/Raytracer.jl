# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Main unit test file


using Test

using Documenter, LinearAlgebra, StaticArrays

using Raytracer
using Raytracer:
    NORMAL_X, NORMAL_Y, NORMAL_Z, VEC_X, VEC_Y, VEC_Z,
    average_luminosity, clamp, luminosity, norm², γ_correction


##############
# Source code


@testset "Color" begin
    include("test_color.jl")
end
@testset "HDR Image" begin
    include("test_hdr_image.jl")
end


@testset "PCG" begin
    include("test_pcg.jl")
end


@testset "Geometry" begin
    include("test_geometry.jl")
end
@testset "Transformations" begin
    include("test_transformations.jl")
end
# @testset "Ray" begin
#     include("test_ray.jl")
# end
# @testset "Camera" begin
#     include("test_cameras.jl")
# end
# @testset "ImageTracer" begin
#     include("test_image_tracer.jl")
# end
# @testset "Material" begin
#     include("test_materials.jl")
# end
# @testset "Shape" begin
#     include("test_shape.jl")
# end
# @testset "Renderers" begin
#     include("test_renderers.jl")
# end


################
# Documentation


# DocMeta.setdocmeta!(Raytracer, :DocTestSetup, :(using Raytracer); recursive=true)
# @testset "Docs" begin
#     doctest(Raytracer, manual=false)
# end
