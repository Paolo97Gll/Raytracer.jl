# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   test_ray.jl
# description:
#   Unit test for camera.jl


@testset "OrthogonalCamera" begin
    cam = OrthogonalCamera(aspect_ratio=2.0)

    # @test_throws ArgumentError fire_ray(cam, -1,  0)
    # @test_throws ArgumentError fire_ray(cam,  0, -1)
    # @test_throws ArgumentError fire_ray(cam,  2,  0)
    # @test_throws ArgumentError fire_ray(cam,  0,  2)

    ray1 = fire_ray(cam, 0.0, 0.0)
    ray2 = fire_ray(cam, 1.0, 0.0)
    ray3 = fire_ray(cam, 0.0, 1.0)
    ray4 = fire_ray(cam, 1.0, 1.0)

    # Verify that the rays are parallel by verifying that cross-products vanish
    @test (ray1.dir × ray2.dir |> norm²) ≈ 0.0 
    @test (ray1.dir × ray3.dir |> norm²) ≈ 0.0 
    @test (ray1.dir × ray4.dir |> norm²) ≈ 0.0 

    # Verify that the ray hitting the corners have the right coordinates
    @test ray1(1.0) ≈ Point(0.0, 2.0, -1.0)
    @test ray2(1.0) ≈ Point(0.0, -2.0, -1.0)
    @test ray3(1.0) ≈ Point(0.0, 2.0, 1.0)
    @test ray4(1.0) ≈ Point(0.0, -2.0, 1.0)

    @testset "transform" begin
        cam = OrthogonalCamera(transformation = translation(-VEC_Y * 2.0) * rotationZ(π/2))
    
        ray = fire_ray(cam, 0.5, 0.5)
        @test ray(1.0) ≈ Point(0.0, -2.0, 0.0)
    end
end


@testset "PerspectiveCamera" begin
    cam = PerspectiveCamera(aspect_ratio=2.0)

    # @test_throws ArgumentError fire_ray(cam, -1,  0)
    # @test_throws ArgumentError fire_ray(cam,  0, -1)
    # @test_throws ArgumentError fire_ray(cam,  2,  0)
    # @test_throws ArgumentError fire_ray(cam,  0,  2)

    ray1 = fire_ray(cam, 0.0, 0.0)
    ray2 = fire_ray(cam, 1.0, 0.0)
    ray3 = fire_ray(cam, 0.0, 1.0)
    ray4 = fire_ray(cam, 1.0, 1.0)

    # Verify that all the rays depart from the same point
    @test ray1.origin ≈ ray2.origin
    @test ray1.origin ≈ ray3.origin
    @test ray1.origin ≈ ray4.origin

    # Verify that the ray hitting the corners have the right coordinates
    @test ray1(1.0) ≈ Point(0.0, 2.0, -1.0)
    @test ray2(1.0) ≈ Point(0.0, -2.0, -1.0)
    @test ray3(1.0) ≈ Point(0.0, 2.0, 1.0)
    @test ray4(1.0) ≈ Point(0.0, -2.0, 1.0)

    @testset "transform" begin
        cam = PerspectiveCamera(transformation = translation(-VEC_Y * 2.0) * rotationZ(π/2))
    
        ray = fire_ray(cam, 0.5, 0.5)
        @test ray(1.0) ≈ Point(0.0, -2.0, 0.0)
    end

    cam = PerspectiveCamera()
    @test aperture_deg(cam) == 90
end