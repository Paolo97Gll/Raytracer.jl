# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Main unit test file


using Test

using Documenter, LinearAlgebra, StaticArrays

using Raytracer, Raytracer.Interpreter


##############
# Source code


@testset "Color" begin
    include("test_colors.jl")
end
@testset "HDR Image" begin
    include("test_hdrimage.jl")
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
@testset "Ray" begin
    include("test_ray.jl")
end
@testset "Cameras" begin
    include("test_cameras.jl")
end
@testset "Materials" begin
    include("test_materials.jl")
end
@testset "Shapes" begin
    include("test_shapes.jl")
end
@testset "World" begin
    include("test_world.jl")
end
@testset "Renderers" begin
    include("test_renderers.jl")
end
@testset "ImageTracer" begin
    include("test_imagetracer.jl")
end

@testset "Interpreter" begin
    include("test_interpreter.jl")
end


################
# Documentation


DocMeta.setdocmeta!(Raytracer, :DocTestSetup, :(using Raytracer); recursive=true)
@testset "Docs" begin
    doctest(Raytracer, manual=false)
end
