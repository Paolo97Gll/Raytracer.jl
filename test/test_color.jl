@testset "Operations" begin
    # testset variables
    c1 = RGB(1., 2., 3.)
    c2 = RGB(.4, .5, .6)

    # test elementwise addition
    @testset "addition" begin
        @test c1 + c2 == RGB(1.4, 2.5, 3.6)
    end

    # test elementwise subtraction
    @testset "subtraction" begin
        @test c1 - c2 == RGB(.6, 1.5, 2.4)
    end
    
    # test scalar multiplication
    @testset "scalar multiplication" begin
        a = 2
        @test a * c1 == RGB(2., 4., 6.)
        @test c1 * a == RGB(2., 4., 6.)
        @test a * c1 == c1 * a
    end
    
    # test elementwise ≈
    @testset "elementwise ≈" begin
        a = 0
        for i in 1:10
            a += .1
        end
        @test RGB(a, 2. * a, 3. * a) ≈ c1
    end
    
    # test elementwise multiplication
    @testset "elementwise multiplication" begin
        @test c1 * c2 == RGB(1. * .4, 2. * .5, 3. * .6)
    end
end


@testset "Iterations" begin
    # testset variables
    r = 1.
    g = 2.
    b = 3.
    c = RGB(r, g, b)

    # test indexing properties
    @testset "indexing properties" begin
        @test length(c) === 3
        @test firstindex(c) === 1
        @test lastindex(c) === 3
    end
    
    # test indexing
    @testset "get index" begin
        # linear indexing
        @test r == c[begin]
        @test r == c[1]
        @test g == c[2]
        @test b == c[end]
        @test b == c[3]

        # test exceptions
        @test_throws BoundsError c[4]
        
        # cartesian indexing
        @test r == c[CartesianIndex(1)]
        @test g == c[CartesianIndex(2)]
        @test b == c[CartesianIndex(3)]

        #test exceptions
        @test_throws BoundsError c[CartesianIndex(4)]
    end

    # test iterability
    @testset "iterability" begin    
        @test all(i == j for (i, j) in zip((r, g, b), c))
    end

    # test splat operator 
    @testset "splat operator" begin
        cc = RGB(c...)
        @test cc === c
    end 
end


@testset "Broadcasting" begin
    c1 = RGB(1., 2., 3.)
    c2 = RGB(4., 5., 6.)
    a = 2

    # testing equivalence to custom defined methods
    @test c1 .+ c2 == c1 + c2
    @test c1 .- c2 == c1 - c2
    @test c1 .* c2 == c1 * c2
    @test a .* c1 == a * c1
    @test c1 .* a == c1 * a

    # broadcasting operators can be applied between any broadcastable type instances
    @test all((.1, .2, .3) .+ c1 ≈ RGB(1.1, 2.2, 3.3))
    @test all((1., 2., 3.) .== c1)

    # it works for any operator valid for the types of the elements
    @test all(c2 ./ c1 ≈ RGB(4., 5 // 2, 2.))
end


@testset "Color manipulation" begin
    c = RGB(1., 2., 3.)
    
    @test luminosity(c) ≈ 2.
    @test _clamp(c) ≈ RGB(1/2, 2/3, 3/4)
end


@testset "IO" begin
    endian_f = little_endian ? ltoh : ntoh

    io = IOBuffer()
    c_f32 = RGB{Float32}(1., 2., 3.)
    c_f64 = RGB{Float64}(1., 2., 3.)

    # test color pretty printing
    @testset "show" begin
        # compact
        show(io, c_f64)
        @test String(take!(io)) == "(1.0 2.0 3.0)"
        # extended
        show(io, "text/plain", c_f64)
        @test String(take!(io)) == "RGB color with eltype Float64\nR: 1.0, G: 2.0, B: 3.0"
    end

    # test color write to IO
    @testset "write" begin
        # Float32
        write(io, c_f32)
        read_value = reinterpret(Float32, take!(io))
        @test all(read_value .=== Array{Float32}([1., 2., 3.]))
        @test RGB(read_value...) === c_f32
        # Other type
        warn_message = "Implicit conversion from Float64 to Float32, since PFM images works with 32bit floating point values"
        @test_logs (:warn, warn_message) write(io, c_f64)
        read_value = reinterpret(Float32, take!(io))
        @test all(read_value .=== Array{Float32}([1., 2., 3.]))
        @test RGB(read_value...) === c_f32
        @test RGB(read_value...) !== c_f64
    end

    @testset "read" begin
        io = IOBuffer()
        test_float = (1.0f0, 2.0f0, 3.0f0, 4.0f0)
        write(io, test_float...)
        seekstart(io)
        @test all(read(io, RGB{Float32}) .== test_float[1:3])
        
        # test exceptions
        @test_throws InvalidRgbStream read(io, RGB{Float32})
    end
end


@testset "Other" begin
    # test eltype
    @testset "eltype" begin
        @test eltype(RGB{Float32}) == Float32
    end

    # test zero
    @testset "zero" begin
        # from type
        @test zero(RGB{Float32}) == RGB{Float32}(0., 0., 0.)
        @test zero(RGB{Float64}) == RGB{Float64}(0., 0., 0.)
        # from variable
        c = RGB(1., 2., 3.)
        @test zero(c) == RGB(0., 0., 0.)
    end

    # test one
    @testset "one" begin
        # from type
        @test one(RGB{Float32}) == RGB{Float32}(1., 1., 1.)
        @test one(RGB{Float64}) == RGB{Float64}(1., 1., 1.)
        # from variable
        c = RGB(1., 2., 3.)
        @test one(c) == RGB(1., 1., 1.)
    end
end