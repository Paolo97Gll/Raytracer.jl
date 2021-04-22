# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   test_geometry.jl
# description:
#   Unit test for geometry.jl


s = 3

vv1 = [1., 2., 3.]
vv2 = [1.5, 3., 4.5]
vv3 = [10., 20., 30.]

sv1 = SVector{size(vv1)...}(vv1)
sv2 = SVector{size(vv2)...}(vv2)
sv3 = SVector{size(vv3)...}(vv3)


# TODO these tests does not work and need to be fixed


@testset "Vec" begin
    v1, v2, v3 = (sv1, vv2, vv3) .|> Vec

    @testset "constructor" begin
        @test v1 == sv1
        @test v2 == sv2
        @test Vec(vv1...) == sv1
    end

    @testset "operations" begin
        @test norm(v1) == norm(sv1)
        @test normalize(v1) == Vec(normalize(sv1))
        @test norm²(v1) ≈ norm(sv1)^2

        @test v1 ⋅ v2 == sv1 ⋅ sv2

        @test v1 + v2 == Vec(sv1 + sv2)
        @test v1 - v2 == Vec(sv1 - sv2)
        @test v1 × v2 == Vec(sv1 × sv2)

        @test s * v1 == v1 * s == Vec(s * sv1)

        @test Vec([15, 30, 45]) ≈ v2 * 10
    end
end

@testset "Normal" begin
    v1, v2, v3 = (sv1, vv2, vv3) .|> Normal 
    
    @testset "constructor" begin
        @test v1 == sv1
        @test v2 == sv2
        @test Normal(vv1...) == sv1
    end

    @testset "operations" begin
        @test norm(v1) == norm(sv1)
        @test normalize(v1) == Normal(normalize(sv1))
        @test norm²(v1) ≈ norm(sv1)^2

        @test v1 ⋅ v2 == sv1 ⋅ sv2

        @test v1 + v2 == Normal(sv1 + sv2)
        @test v1 - v2 == Normal(sv1 - sv2)
        @test v1 × v2 == Normal(sv1 × sv2)

        @test s * v1 == v1 * s == Normal(s * sv1)

        @test Normal([15, 30, 45]) ≈ v2 * 10
    end
end


@testset "Point" begin
    p1, p2 = (sv1, vv2) .|> Point
    v = Vec(vv3)

    @testset "constructor" begin
        @test p1.v == sv1
        @test p2.v == sv2
        @test_throws ArgumentError Point(ones(4))
    end

    @testset "operations" begin
        @test p1 ≈ Point(vv3 ./ 10)  

        @test p1 - p2 == Vec(sv1 - sv2)

        @test p1 + v == Point(sv1 + sv3)
        @test p1 - v == Point(sv1 - sv3)

        @test Point([15, 30, 45]) ≈ p2 * 10
    end
end