# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Unit test file for geometry.jl


s = 3

vv1 = [  1f0,  2f0,   3f0]
vv2 = [1.5f0,  3f0, 4.5f0]
vv3 = [ 10f0, 20f0,  30f0]

sv1 = SVector{size(vv1)...}(vv1)
sv2 = SVector{size(vv2)...}(vv2)
sv3 = SVector{size(vv3)...}(vv3)


@testset "Vec" begin
    v1, v2, v3 = (sv1, vv2, vv3) .|> Vec

    @testset "constructor" begin
        @test v1 == sv1
        @test v2 == sv2
        @test Vec(vv1...) == sv1
    end

    @testset "operations" begin
        @test -v1 ≈ -sv1

        @test norm(v1) === norm(sv1)
        @test normalize(v1) === Vec(normalize(sv1))
        @test norm²(v1) ≈ norm(sv1)^2

        @test v1 ⋅ v2 === sv1 ⋅ sv2

        @test v1 + v2 === Vec(sv1 + sv2)
        @test v1 - v2 === Vec(sv1 - sv2)
        @test v1 × v2 === Vec(sv1 × sv2)

        @test s * v1 === v1 * s === Vec(s * sv1)

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
        @test norm(v1) === norm(sv1)
        @test normalize(v1) === Normal{true}(normalize(sv1))
        @test norm²(v1) ≈ norm(sv1)^2

        @test v1 ⋅ v2 === sv1 ⋅ sv2

        @test v1 + v2 === Normal(sv1 + sv2)
        @test v1 - v2 === Normal(sv1 - sv2)
        @test v1 × v2 === Normal(sv1 × sv2)

        @test s * v1 === v1 * s === Normal(s * sv1)

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


@testset "ONB" begin
	pcg = PCG()

	@test begin
        for _ ∈ 1:100_000
            normal = Normal(rand(pcg, Float32, 3)) |> normalize

            e1, e2, e3 = create_onb_from_z(normal)
            
            # Verify that the z axis is aligned with the normal
            @assert e3 ≈ normal

            # Verify that the base is orthogonal
            atol = √(eps(eltype(normal))) # nonstandard approximation threshold
            @assert isapprox(e1 ⋅ e2, 0, atol=atol)
            @assert isapprox(e2 ⋅ e3, 0, atol=atol)
            @assert isapprox(e3 ⋅ e1, 0, atol=atol)

            # Verify that each component is normalized
            @assert norm²(e1) ≈ 1
            @assert norm²(e2) ≈ 1
            @assert norm²(e3) ≈ 1
        end
        true
    end
end
