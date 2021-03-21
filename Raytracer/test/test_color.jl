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

        # test indexing
        @test r == c[begin] == c[1]
        @test g == c[2]
        @test b == c[end] == c[3]
        @test_throws BoundsError c[4]

        # test iterability
        @test all(i == j for (i, j) in zip((r, g, b), c))
        
        # test splat operator 
        cc = RGB(c...)
        @test cc == c
    end


    @testset "Broadcasting" begin
        c1 = RGB(1., 2., 3.)
        c2 = RGB(4., 5., 6.)
        a = 2

        # testing equivalence to custom defined methods
        @test c1 .+ c2 == c1 + c2
        @test c1 .- c2 == c1 - c2
        @test c1 .* c2 == c1 * c2
        @test a .* c2 == a * c2

        # broadcasting operators can be applied between any broadcastable type instances
        @test all(true == el for el in ((.1, .2, .3) .+ c1 .≈ RGB(1.1, 2.2, 3.3)))
        @test all(true == el for el in ((1., 2., 3.) .== c1))

        # it works for any operator valid for the types of the elements
        @test all(true == el for el in (c2 ./ c1 .≈ RGB(4., 5 // 2, 2.)))
    end


    @testset "IO" begin
        c = RGB(1., 2., 3.)

        # test color pretty printing (compact)
        io = IOBuffer()
        show(io, c)
        @test String(take!(io)) == "(1.0 2.0 3.0)"
        
        # test color pretty printing (extended)
        io = IOBuffer()
        show(io, "text/plain", c)
        @test String(take!(io)) == "RGB color with eltype Float64\nR: 1.0, G: 2.0, B: 3.0"

        # test color write to IO (Float32)
        io = IOBuffer()
        c_f32 = RGB{Float32}(1., 2., 3.)
        write(io, c_f32)
        @test reinterpret(Float32, take!(io)) == [1., 2., 3.]

        # test color write to IO (Float64)
        io = IOBuffer()
        write(io, c)
        @test reinterpret(Float32, take!(io)) == [1., 2., 3.]
        # test warning
        warn_message = "Implicit conversion from Float64 to Float32, since PFM images works with 32bit floating point values"
        @test_logs (:warn, warn_message) write(io, c)
    end


    @testset "Other" begin
        # test zero from type
        @test zero(RGB{Float32}) == RGB{Float32}(0., 0., 0.)
        @test zero(RGB{Float64}) == RGB{Float64}(0., 0., 0.)
        # test zero from variable
        c = RGB(1., 2., 3.)
        @test zero(c) == RGB(0., 0., 0.)

        # test one from type
        @test one(RGB{Float32}) == RGB{Float32}(1., 1., 1.)
        @test one(RGB{Float64}) == RGB{Float64}(1., 1., 1.)
        # test one from variable
        c = RGB(1., 2., 3.)
        @test one(c) == RGB(1., 1., 1.)
    end
end