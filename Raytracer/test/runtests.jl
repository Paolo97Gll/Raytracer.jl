using Raytracer   # Mettete il nome che avete scelto
using Test
using ColorTypes.RGB

c1 = RGB(.3, .6, .7)
c2 = RGB(.4, .5, .8)

@testset "Colors" begin
    # Put here the tests required for color sum and product
    @test 1 + 1 == 2
    @test c1 + c2 ≈ RGB(.7, 1.1, 1.5)
    @test c1 - c2 ≈ RGB(-.1, .1, -.1)
end
