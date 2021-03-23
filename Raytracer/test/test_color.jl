@testset "Color" begin
    @testset "Operations" begin
        c1 = RGB(1., 2., 3.)
        c2 = RGB(.4, .5, .6)

        # test elementwise addition
        @test c1 + c2 == RGB(1.4, 2.5, 3.6)

        # test elementwise subtraction
        @test c1 - c2 == RGB(.6, 1.5, 2.4)

        # test scalar multiplication
        a = 2
        @test a * c1 == RGB(2., 4., 6.)
        @test c1 * a == RGB(2., 4., 6.)
        @test a * c1 == c1 * a

        # test elementwise ≈
        a = 0
        for i in 1:10
            a += .1
        end
        @test RGB(a, 2. * a, 3. * a) ≈ c1

        # test elementwise multiplication
        @test c1 * c2 == RGB(1. * .4, 2. * .5, 3. * .6)
    end


    @testset "Iterations" begin
        r = 1.
        g = 2.
        b = 3.
        c = RGB(r, g, b)

        # test indexing properties
        @test length(c) === 3
        @test firstindex(c) === 1
        @test lastindex(c) === 3

        # test indexing
        @test r == c[begin]
        @test r == c[1]
        @test g == c[2]
        @test b == c[end]
        @test b == c[3]
        @test_throws BoundsError c[4]

        @test r == c[CartesianIndex(1)]
        @test g == c[CartesianIndex(2)]
        @test b == c[CartesianIndex(3)]
        @test_throws BoundsError c[CartesianIndex(4)]

        # test iterability
        @test all(i == j for (i, j) in zip((r, g, b), c))

        # test splat operator 
        cc = RGB(c...)
        @test cc === c
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
        @test all(true == el for el in ((.1, .2, .3) .+ c1 .≈ RGB(1.1, 2.2, 3.3)))
        @test all(true == el for el in ((1., 2., 3.) .== c1))

        # it works for any operator valid for the types of the elements
        @test all(true == el for el in (c2 ./ c1 .≈ RGB(4., 5 // 2, 2.)))
    end


    @testset "IO" begin
        io = IOBuffer()
        c_f32 = RGB{Float32}(1., 2., 3.)
        c_f64 = RGB{Float64}(1., 2., 3.)

        # test color pretty printing
        # compact
        show(io, c_f64)
        @test String(take!(io)) == "(1.0 2.0 3.0)"
        # extended
        show(io, "text/plain", c_f64)
        @test String(take!(io)) == "RGB color with eltype Float64\nR: 1.0, G: 2.0, B: 3.0"

        # test color write to IO
        # Float32
        write(io, c_f32)
        readed_value = reinterpret(Float32, take!(io))
        @test all(readed_value .=== Array{Float32}([1., 2., 3.]))
        @test RGB(readed_value...) === c_f32
        # Other type
        warn_message = "Implicit conversion from Float64 to Float32, since PFM images works with 32bit floating point values"
        @test_logs (:warn, warn_message) write(io, c_f64)
        readed_value = reinterpret(Float32, take!(io))
        @test all(readed_value .=== Array{Float32}([1., 2., 3.]))
        @test RGB(readed_value...) === c_f32
        @test RGB(readed_value...) !== c_f64
    end


    @testset "Other" begin
        # test eltype
        @test eltype(RGB{Float32}) == Float32

        # test zero
        # from type
        @test zero(RGB{Float32}) == RGB{Float32}(0., 0., 0.)
        @test zero(RGB{Float64}) == RGB{Float64}(0., 0., 0.)
        # from variable
        c = RGB(1., 2., 3.)
        @test zero(c) == RGB(0., 0., 0.)

        # test one
        # from type
        @test one(RGB{Float32}) == RGB{Float32}(1., 1., 1.)
        @test one(RGB{Float64}) == RGB{Float64}(1., 1., 1.)
        # from variable
        c = RGB(1., 2., 3.)
        @test one(c) == RGB(1., 1., 1.)
    end
end