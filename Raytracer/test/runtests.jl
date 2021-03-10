using Raytracer
using Test
import ColorTypes.RGB

@testset "ColorsOperations" begin
    @test 1 + 1 == 2
    let c1 = RGB(1., 2., 3.), c2 = RGB(.4, .5, .6), a = 2
        # test elementwise addition
        @test c1 + c2 == RGB(1.4, 2.5, 3.6)

        # test elementwise subtraction
        @test c1 - c2 == RGB(.6, 1.5, 2.4)

        # test scalar multiplication
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
end
