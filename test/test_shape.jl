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
        @test intersect ≈ HitRecord(Point(0, 0, 1), VEC_Z |> Normal, Vec2D(NaN,0), 1., ray, Material())
    end

    @testset "from_behind" begin
        ray = Ray{Float64}(Point(3,0,0), -VEC_X)
        shape = Sphere()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(1, 0, 0), VEC_X |> Normal, Vec2D(0, 0.5), 2., ray, Material())
    end

    @testset "from_within" begin
        ray = Ray{Float64}(Point(0,0,0), VEC_X)
        shape = Sphere()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(1, 0, 0), -VEC_X |> Normal, Vec2D(0, 0.5), 1., ray, Material())
    end

    @testset "transposed_from_above" begin
        ray = Ray{Float64}(Point(10,0,2), -VEC_Z)
        shape = Sphere(transformation = translation(Vec(10,0,0)))
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(10, 0, 1), VEC_Z |> Normal, Vec2D(NaN, 0), 1., ray, Material())
    end

    @testset "transposed_from_behind" begin
        ray = Ray{Float64}(Point(13,0,0), -VEC_X)
        shape = Sphere(transformation = translation(Vec(10,0,0)))
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(11, 0, 0), VEC_X |> Normal, Vec2D(0, 0.5), 2., ray, Material())
    end
    
    @testset "miss_transposed_from_above" begin
        ray = Ray{Float64}(Point(0,0,2), -VEC_Z)
        shape = Sphere(transformation = translation(Vec(10,0,0)))
        intersect = ray_intersection(ray, shape) 
        @test intersect === nothing
    end

    @testset "miss_transposed_from_behind" begin
        ray = Ray{Float64}(Point(-10,0,0), -VEC_X)
        shape = Sphere(transformation = translation(Vec(10,0,0)))
        intersect = ray_intersection(ray, shape) 
        @test intersect === nothing
    end
end

@testset "Plane" begin
    @testset "from_above" begin
        ray = Ray{Float64}(Point(0,0,1), -VEC_Z)
        shape = Plane()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(0, 0, 0), VEC_Z |> Normal, Vec2D(0,0), 1., ray, Material())
    end

    @testset "laid_on" begin
        ray = Ray{Float64}(Point(0,0,0), VEC_X)
        shape = Plane()
        intersect = ray_intersection(ray, shape) 
        @test intersect === nothing
    end

    @testset "from_below" begin
        ray = Ray{Float64}(Point(0,0,-1), VEC_Z)
        shape = Plane()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(0, 0, 0), -VEC_Z |> Normal, Vec2D(0, 0), 1., ray, Material())
    end

    @testset "transposed_from_above" begin
        ray = Ray{Float64}(Point(1.5,0.5,3), -VEC_Z)
        shape = Plane(transformation = translation(Vec(0,0,1)))
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(1.5, 0.5, 1), VEC_Z |> Normal, Vec2D(0.5, 0.5), 2., ray, Material())
    end

    @testset "from_diagonal" begin
        ray = Ray{Float64}(Point(0,0,1), -VEC_Z + VEC_X + VEC_Y)
        shape = Plane()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(1., 1., 0.), VEC_Z |> Normal, Vec2D(0., 0.), 1., ray, Material())
    end
end