# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Unit test file for color.jl


@testset "operations" begin
    c1 = RGB(1f0, 2f0, 3f0)
    c2 = RGB(0.4f0, 0.5f0, 0.6f0)

    @testset "addition" begin
        @test c1 + c2 == RGB(1.4f0, 2.5f0, 3.6f0)
    end

    @testset "subtraction" begin
        @test c1 - c2 == RGB(0.6f0, 1.5f0, 2.4f0)
    end

    @testset "scalar multiplication" begin
        a = 2
        @test a * c1 == RGB(2f0, 4f0, 6f0)
        @test c1 * a == RGB(2f0, 4f0, 6f0)
        @test a * c1 == c1 * a
    end

    @testset "elementwise ≈" begin
        a = 0
        for i in 1:10
            a += 0.1f0
        end
        @test RGB(a, 2f0 * a, 3f0 * a) ≈ c1
    end

    @testset "elementwise multiplication" begin
        @test c1 * c2 == RGB(1f0 * 0.4f0, 2f0 * 0.5f0, 3f0 * 0.6f0)
    end
end


@testset "iterations" begin
    r = 1f0
    g = 2f0
    b = 3f0
    c = RGB(r, g, b)

    @testset "indexing properties" begin
        @test length(c) === 3
        @test firstindex(c) === 1
        @test lastindex(c) === 3
    end

    @testset "get index" begin
        # linear indexing
        @test r == c[begin]
        @test r == c[1]
        @test g == c[2]
        @test b == c[end]
        @test b == c[3]
        @test_throws BoundsError c[4]

        # cartesian indexing
        @test r == c[CartesianIndex(1)]
        @test g == c[CartesianIndex(2)]
        @test b == c[CartesianIndex(3)]
        @test_throws BoundsError c[CartesianIndex(4)]
    end

    @testset "iterability" begin
        @test all(i == j for (i, j) in zip((r, g, b), c))
    end

    @testset "splat operator" begin
        cc = RGB(c...)
        @test cc === c
    end
end


@testset "broadcasting" begin
    c1 = RGB(1f0, 2f0, 3f0)
    c2 = RGB(4f0, 5f0, 6f0)
    a = 2

    # testing equivalence to custom defined methods
    @test c1 .+ c2 == c1 + c2
    @test c1 .- c2 == c1 - c2
    @test c1 .* c2 == c1 * c2
    @test a .* c1 == a * c1
    @test c1 .* a == c1 * a

    # broadcasting operators can be applied between any broadcastable type instances
    @test all((0.1f0, 0.2f0, 0.3f0) .+ c1 ≈ RGB(1.1f0, 2.2f0, 3.3f0))
    @test all((1f0, 2f0, 3f0) .== c1)

    # it works for any operator valid for the types of the elements
    @test all(c2 ./ c1 ≈ RGB(4f0, 5f0/2f0, 2f0))
end


@testset "color manipulation" begin
    c = RGB(1f0, 2f0, 3f0)

    @test luminosity(c) ≈ 2f0
    @test clamp(c) ≈ RGB(1f0/2f0, 2f0/3f0, 3f0/4f0)
    @test γ_correction(c, 1f0) ≈ c
    @test γ_correction(c, 1.2f0) ≈ RGB(1f0^(1/1.2), 2f0^(1/1.2), 3f0^(1/1.2))
end


@testset "IO" begin
    endian_f = ENDIAN_BOM == 0x04030201 ? ltoh : ntoh

    io = IOBuffer()
    c = RGB(1f0, 2f0, 3f0)

    @testset "show" begin
        # compact
        show(io, c)
        @test String(take!(io)) == "(1.0 2.0 3.0)"
        # extended
        show(io, "text/plain", c)
        @test String(take!(io)) == "RGB color with eltype Float32\nR: 1.0, G: 2.0, B: 3.0"
    end
end


@testset "other" begin
    @testset "eltype" begin
        @test eltype(RGB{Float32}) == Float32
    end

    @testset "zero" begin
        # from type
        @test zero(RGB{Float32}) == RGB(0f0, 0f0, 0f0)
        # from variable
        c = RGB(1f0, 2f0, 3f0)
        @test zero(c) == RGB(0f0, 0f0, 0f0)
    end

    @testset "one" begin
        # from type
        @test one(RGB{Float32}) == RGB(1f0, 1f0, 1f0)
        # from variable
        c = RGB(1f0, 2f0, 3f0)
        @test one(c) == RGB(1f0, 1f0, 1f0)
    end
end
