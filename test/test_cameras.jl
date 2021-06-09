# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Unit test file for camera.jl


@testset "OrthogonalCamera" begin
    cam = OrthogonalCamera(aspect_ratio=2f0)

    ray1 = fire_ray(cam, 0f0, 0f0)
    ray2 = fire_ray(cam, 1f0, 0f0)
    ray3 = fire_ray(cam, 0f0, 1f0)
    ray4 = fire_ray(cam, 1f0, 1f0)

    # Verify that the rays are parallel by verifying that cross-products vanish
    @test (ray1.dir × ray2.dir |> norm²) ≈ 0f0
    @test (ray1.dir × ray3.dir |> norm²) ≈ 0f0
    @test (ray1.dir × ray4.dir |> norm²) ≈ 0f0

    # Verify that the ray hitting the corners have the right coordinates
    @test ray1(1f0) ≈ Point(0f0, 2f0, -1f0)
    @test ray2(1f0) ≈ Point(0f0, -2f0, -1f0)
    @test ray3(1f0) ≈ Point(0f0, 2f0, 1f0)
    @test ray4(1f0) ≈ Point(0f0, -2f0, 1f0)

    @testset "transform" begin
        cam = OrthogonalCamera(transformation = translation(-VEC_Y * 2f0) * rotationZ(π/2))

        ray = fire_ray(cam, 0.5f0, 0.5f0)
        @test ray(1f0) ≈ Point(0f0, -2f0, 0f0)
    end
end


@testset "PerspectiveCamera" begin
    cam = PerspectiveCamera(aspect_ratio=2f0)

    ray1 = fire_ray(cam, 0f0, 0f0)
    ray2 = fire_ray(cam, 1f0, 0f0)
    ray3 = fire_ray(cam, 0f0, 1f0)
    ray4 = fire_ray(cam, 1f0, 1f0)

    # Verify that all the rays depart from the same point
    @test ray1.origin ≈ ray2.origin
    @test ray1.origin ≈ ray3.origin
    @test ray1.origin ≈ ray4.origin

    # Verify that the ray hitting the corners have the right coordinates
    @test ray1(1f0) ≈ Point(0f0, 2f0, -1f0)
    @test ray2(1f0) ≈ Point(0f0, -2f0, -1f0)
    @test ray3(1f0) ≈ Point(0f0, 2f0, 1f0)
    @test ray4(1f0) ≈ Point(0f0, -2f0, 1f0)

    @testset "transform" begin
        cam = PerspectiveCamera(transformation = translation(-VEC_Y * 2f0) * rotationZ(π/2))

        ray = fire_ray(cam, 0.5f0, 0.5f0)
        @test ray(1f0) ≈ Point(0f0, -2f0, 0f0)
    end

    cam = PerspectiveCamera()
    @test aperture_deg(cam) == 90
end
