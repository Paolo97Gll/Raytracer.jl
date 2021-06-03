# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   test_shape.jl
# description:
#   Unit tests for shape.jl

@testset "World" begin
    @testset "RayIntersection" begin
        world = World()

        sphere1 = Sphere(transformation=translation(vec_x() * 2))
        sphere2 = Sphere(transformation=translation(vec_x() * 8))
        push!(world, sphere1)
        push!(world, sphere2)

        intersection1 = ray_intersection(Ray(
            Point(0.0, 0.0, 0.0), vec_x()
        ), world)
        @test intersection1 !== nothing
        @test intersection1.world_point ≈ Point(1.0, 0.0, 0.0)

        intersection2 = ray_intersection(Ray(
            Point(10.0, 0.0, 0.0), -vec_x()
        ), world)

        @test intersection2 !== nothing
        @test intersection2.world_point ≈ Point(9.0, 0.0, 0.0)
    end
end

@testset "Sphere" begin
    @testset "from_above" begin
        ray = Ray{Float64}(Point(0,0,2), -vec_z())
        shape = Sphere()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point{Float64}(0, 0, 1), normal_z(Float64, false), Vec2D{Float64}(0, 0), 1., ray, Material())
    end

    @testset "from_behind" begin
        ray = Ray{Float64}(Point(3,0,0), -vec_x())
        shape = Sphere()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point{Float64}(1, 0, 0), normal_x(Float64, false), Vec2D{Float64}(0.0, 0.5), 2., ray, Material())
    end

    @testset "from_within" begin
        ray = Ray{Float64}(Point(0,0,0), vec_x())
        shape = Sphere()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point{Float64}(1, 0, 0), -normal_x(Float64, false), Vec2D{Float64}(0.0, 0.5), 1., ray, Material())
    end

    @testset "transposed_from_above" begin
        ray = Ray{Float64}(Point(10,0,2), -vec_z())
        shape = Sphere(transformation = translation(Vec(10,0,0)))
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point{Float64}(10, 0, 1), normal_z(Float64, false), Vec2D{Float64}(0, 0), 1., ray, Material())
    end

    @testset "transposed_from_behind" begin
        ray = Ray{Float64}(Point(13,0,0), -vec_x())
        shape = Sphere(transformation = translation(Vec(10,0,0)))
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point{Float64}(11, 0, 0), normal_x(Float64, false), Vec2D{Float64}(0.0, 0.5), 2., ray, Material())
    end
    
    @testset "miss_transposed_from_above" begin
        ray = Ray{Float64}(Point(0,0,2), -vec_z())
        shape = Sphere(transformation = translation(Vec(10,0,0)))
        intersect = ray_intersection(ray, shape) 
        @test intersect === nothing
    end

    @testset "miss_transposed_from_behind" begin
        ray = Ray{Float64}(Point(-10,0,0), -vec_x())
        shape = Sphere(transformation = translation(Vec(10,0,0)))
        intersect = ray_intersection(ray, shape) 
        @test intersect === nothing
    end
end

@testset "Plane" begin
    @testset "from_above" begin
        ray = Ray{Float64}(Point(0,0,1), -vec_z())
        shape = Plane()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point{Float64}(0, 0, 0), normal_z(Float64, false), Vec2D{Float64}(0,0), 1., ray, Material())
    end

    @testset "laid_on" begin
        ray = Ray{Float64}(Point(0,0,0), vec_x())
        shape = Plane()
        intersect = ray_intersection(ray, shape) 
        @test intersect === nothing
    end

    @testset "from_below" begin
        ray = Ray{Float64}(Point(0,0,-1), vec_z())
        shape = Plane()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point{Float64}(0, 0, 0), -normal_z(Float64, false), Vec2D{Float64}(0, 0), 1., ray, Material())
    end

    @testset "transposed_from_above" begin
        ray = Ray{Float64}(Point(1.5,0.5,3), -vec_z())
        shape = Plane(transformation = translation(Vec(0,0,1)))
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point{Float64}(1.5, 0.5, 1), normal_z(Float64, false), Vec2D{Float64}(0.5, 0.5), 2., ray, Material())
    end

    @testset "from_diagonal" begin
        ray = Ray{Float64}(Point(0,0,1), -vec_z() + vec_x() + vec_y())
        shape = Plane()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point{Float64}(1., 1., 0.), normal_z(Float64, false), Vec2D{Float64}(0., 0.), 1., ray, Material())
    end
end