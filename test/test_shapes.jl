# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Unit test file for shapes.jl


@testset "Sphere" begin
    @testset "from_above" begin
        ray = Ray(Point(0f0, 0f0, 2f0), -VEC_Z)
        shape = Sphere()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(0f0, 0f0, 1f0), NORMAL_Z_false, Vec2D(0f0, 0f0), 1f0, ray, Material())
    end

    @testset "from_behind" begin
        ray = Ray(Point(3f0, 0f0, 0f0), -VEC_X)
        shape = Sphere()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(1f0, 0f0, 0f0), NORMAL_X_false, Vec2D(0f0, 0.5f0), 2f0, ray, Material())
    end

    @testset "from_within" begin
        ray = Ray(Point(0f0, 0f0, 0f0), VEC_X)
        shape = Sphere()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(1f0, 0f0, 0f0), -NORMAL_X_false, Vec2D(0.0, 0.5), 1f0, ray, Material())
    end

    @testset "transposed_from_above" begin
        ray = Ray(Point(10f0, 0f0, 2f0), -VEC_Z)
        shape = Sphere(transformation = translation(Vec(10f0, 0f0, 0f0)))
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(10f0, 0f0, 1f0), NORMAL_Z_false, Vec2D(0f0, 0f0), 1f0, ray, Material())
    end

    @testset "transposed_from_behind" begin
        ray = Ray(Point(13f0, 0f0, 0f0), -VEC_X)
        shape = Sphere(transformation = translation(Vec(10f0, 0f0, 0f0)))
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(11f0, 0f0, 0f0), NORMAL_X_false, Vec2D(0f0, 0.5f0), 2f0, ray, Material())
    end
    
    @testset "miss_transposed_from_above" begin
        ray = Ray(Point(0f0, 0f0, 2f0), -VEC_Z)
        shape = Sphere(transformation = translation(Vec(10f0, 0f0, 0f0)))
        intersect = ray_intersection(ray, shape) 
        @test intersect === nothing
    end

    @testset "miss_transposed_from_behind" begin
        ray = Ray(Point(-10f0, 0f0, 0f0), -VEC_X)
        shape = Sphere(transformation = translation(Vec(10f0, 0f0, 0f0)))
        intersect = ray_intersection(ray, shape) 
        @test intersect === nothing
    end
end


@testset "Plane" begin
    @testset "from_above" begin
        ray = Ray(Point(0f0, 0f0, 1f0), -VEC_Z)
        shape = Plane()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(0f0, 0f0, 0f0), NORMAL_Z_false, Vec2D(0f0, 0f0), 1f0, ray, Material())
    end

    @testset "laid_on" begin
        ray = Ray(Point(0f0, 0f0, 0f0), VEC_X)
        shape = Plane()
        intersect = ray_intersection(ray, shape) 
        @test intersect === nothing
    end

    @testset "from_below" begin
        ray = Ray(Point(0f0, 0f0, -1f0), VEC_Z)
        shape = Plane()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(0f0, 0f0, 0f0), -NORMAL_Z_false, Vec2D(0f0, 0f0), 1f0, ray, Material())
    end

    @testset "transposed_from_above" begin
        ray = Ray(Point(1.5f0, 0.5f0, 3), -VEC_Z)
        shape = Plane(transformation = translation(Vec(0f0, 0f0, 1f0)))
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(1.5f0, 0.5f0, 1f0), NORMAL_Z_false, Vec2D(0.5f0, 0.5f0), 2f0, ray, Material())
    end

    @testset "from_diagonal" begin
        ray = Ray(Point(0f0, 0f0, 1f0), -VEC_Z + VEC_X + VEC_Y)
        shape = Plane()
        intersect = ray_intersection(ray, shape) 
        @test intersect ≈ HitRecord(Point(1f0, 1f0, 0f0), NORMAL_Z_false, Vec2D(0f0, 0f0), 1f0, ray, Material())
    end
end
