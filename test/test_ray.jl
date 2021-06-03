# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Unit test file for ray.jl


@testset "constructor" begin
    ray1 = Ray(Point(1f0, 2f0, 3f0), Vec(5f0, 4f0, -1f0))
    ray2 = Ray(Point(1f0, 2f0, 3f0), Vec(5f0, 4f0, -1f0))
    ray3 = Ray(Point(5f0, 1f0, 4f0), Vec(3f0, 9f0, 4f0))

    @test ray1 ≈ ray2
    @test !(ray1 ≈ ray3)
end


@testset "methods" begin
    ray = Ray(Point(1f0, 2f0, 4f0), Vec(4f0, 2f0, 1f0))
    @test ray(0f0) ≈ ray.origin
    @test ray(1f0) ≈ Point(5f0, 4f0, 5f0)
    @test ray(2f0) ≈ Point(9f0, 6f0, 6f0)

    ray = Ray(Point(1f0, 2f0, 3f0), Vec(1f0, 2f0, 3f0))
    m = Transformation([1f0 2f0 3f0 4f0;
                        5f0 6f0 7f0 8f0;
                        9f0 9f0 8f0 7f0;
                        0f0 0f0 0f0 1f0],
                       [-3.75f0 2.75f0 -1f0 0f0;
                        5.75f0 -4.75f0 2f0 1f0;
                        -2.25f0 2.25f0 -1f0 -2f0;
                        0f0 0f0 0f0 1f0])
    @test m * ray ≈ Ray(Point(18f0, 46f0, 58f0), Vec(14f0, 38f0, 51f0))
end

@testset "transform" begin
    ray = Ray(Point(1f0, 2f0, 3f0), Vec(6f0, 5f0, 4f0))
    transformation = translation(Vec(10f0, 11f0, 12f0)) * rotationX(π/2)
    transformed = transformation * ray

    @test transformed.origin ≈ Point(11f0, 8f0, 14f0)
    @test transformed.dir ≈ Vec(6f0, -4f0, 5f0)
end
