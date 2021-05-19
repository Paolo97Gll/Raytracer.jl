# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   test_shape.jl
# description:
#   Unit tests for shape.jl


@testset "Sphere" begin
    @testset "from_above" begin
        ray = Ray{Float64}(Point(0,0,2), -VEC_Z)
        shape = Sphere()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(0, 0, 1), VEC_Z |> Normal, Vec2D(NaN,0), 1., ray)
    end

    @testset "from_behind" begin
        ray = Ray{Float64}(Point(3,0,0), -VEC_X)
        shape = Sphere()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(1, 0, 0), VEC_X |> Normal, Vec2D(0, 0.5), 2., ray)
    end

    @testset "from_within" begin
        ray = Ray{Float64}(Point(0,0,0), VEC_X)
        shape = Sphere()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(1, 0, 0), -VEC_X |> Normal, Vec2D(0, 0.5), 1., ray)
    end

    @testset "transposed_from_above" begin
        ray = Ray{Float64}(Point(10,0,2), -VEC_Z)
        shape = Sphere(translation(Vec(10,0,0)))
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(10, 0, 1), VEC_Z |> Normal, Vec2D(NaN, 0), 1., ray)
    end

    @testset "transposed_from_behind" begin
        ray = Ray{Float64}(Point(13,0,0), -VEC_X)
        shape = Sphere(translation(Vec(10,0,0)))
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(11, 0, 0), VEC_X |> Normal, Vec2D(0, 0.5), 2., ray)
    end
    
    @testset "miss_transposed_from_above" begin
        ray = Ray{Float64}(Point(0,0,2), -VEC_Z)
        shape = Sphere(translation(Vec(10,0,0)))
        intersect = ray_intersection(ray, shape) 
        @test intersect === nothing
    end

    @testset "miss_transposed_from_behind" begin
        ray = Ray{Float64}(Point(-10,0,0), -VEC_X)
        shape = Sphere(translation(Vec(10,0,0)))
        intersect = ray_intersection(ray, shape) 
        @test intersect === nothing
    end
end