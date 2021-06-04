# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Unit test file for world.jl


@testset "World" begin
    @testset "RayIntersection" begin
        world = World()

        sphere1 = Sphere(transformation=translation(VEC_X * 2f0))
        sphere2 = Sphere(transformation=translation(VEC_X * 8f0))
        push!(world, sphere1)
        push!(world, sphere2)

        intersection1 = ray_intersection(Ray(Point(0f0, 0f0, 0f0), VEC_X), world)
        @test intersection1 !== nothing
        @test intersection1.world_point ≈ Point(1f0, 0f0, 0f0)

        intersection2 = ray_intersection(Ray(Point(10f0, 0f0, 0f0), -VEC_X), world)

        @test intersection2 !== nothing
        @test intersection2.world_point ≈ Point(9f0, 0f0, 0f0)
    end
end
