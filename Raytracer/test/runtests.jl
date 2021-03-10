using Raytracer   # Mettete il nome che avete scelto
using Test
import ColorTypes

@testset "Colors" begin
    @test 1 + 1 == 2
    c1 = ColorTypes.RGB(1., 2., 3.)
    c2 = ColorTypes.RGB(.4, .5, .6)
    a = 2
    #test scalar multiplication
    @test a * c1 == ColorTypes.RGB(2., 4., 6.) 
    @test c1 * a == ColorTypes.RGB(2., 4., 6.) 
    @test a * c1 == c1 * a

    #test elementwise ≈
    a = 0
    for i in 1:10
        a += .1
    end
    @test ColorTypes.RGB(a, 2. * a, 3. * a) ≈ c1

    #test elementwise multiplication
    @test c1 * c2 ≈ ColorTypes.RGB(1. * .4, 2. * .5, 3. * .6)
end