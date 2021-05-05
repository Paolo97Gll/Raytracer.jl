# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   test_ray.jl
# description:
#   Unit test for ray.jl


@testset "constructor" begin
    ray1 = Ray(Point(1.0, 2.0, 3.0), Vec(5.0, 4.0, -1.0))
    ray2 = Ray(Point(1.0, 2.0, 3.0), Vec(5.0, 4.0, -1.0))
    ray3 = Ray(Point(5.0, 1.0, 4.0), Vec(3.0, 9.0, 4.0))

    @test ray1 ≈ ray2
    @test !(ray1 ≈ ray3)
end


@testset "methods" begin
    ray = Ray(Point(1.0, 2.0, 4.0), Vec(4.0, 2.0, 1.0))
    @test ray(0.0) ≈ ray.origin
    @test ray(1.0) ≈ Point(5.0, 4.0, 5.0)
    @test ray(2.0) ≈ Point(9.0, 6.0, 6.0)

    ray = Ray(Point(1.0, 2.0, 3.0), Vec(1.0, 2.0, 3.0))
    m = Transformation([1.0 2.0 3.0 4.0;
                        5.0 6.0 7.0 8.0;
                        9.0 9.0 8.0 7.0;
                        0.0 0.0 0.0 1.0],
                       [-3.75 2.75 -1 0;
                        5.75 -4.75 2.0 1.0;
                        -2.25 2.25 -1.0 -2.0;
                        0.0 0.0 0.0 1.0])
    @test m * ray ≈ Ray(Point(18.0, 46.0, 58.0), Vec(14.0, 38.0, 51.0))
end

@testset "transform" begin
    ray = Ray(Point(1.0, 2.0, 3.0), Vec(6.0, 5.0, 4.0))
    transformation = translation(Vec(10.0, 11.0, 12.0)) * rotationX(π/2)
    transformed = transformation * ray

    @test transformed.origin ≈ Point(11.0, 8.0, 14.0)
    @test transformed.dir ≈ Vec(6.0, -4.0, 5.0)
end