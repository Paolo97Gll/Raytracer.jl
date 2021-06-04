# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Unit test file for materials.jl


@testset "pigments" begin
    @testset "UniformPigment" begin
        color = RGB(1f0, 2f0, 3f0)
        pigment = UniformPigment(color=color)

        @test pigment(0f0, 0f0) ≈ color
        @test pigment(1f0, 0f0) ≈ color
        @test pigment(0f0, 1f0) ≈ color
        @test pigment(1f0, 1f0) ≈ color
    end

    @testset "ImagePigment" begin
        image = HdrImage(2, 2)
        image[1, 1] = RGB(1f0, 2f0, 3f0)
        image[2, 1] = RGB(2f0, 3f0, 1f0)
        image[1, 2] = RGB(2f0, 1f0, 3f0)
        image[2, 2] = RGB(3f0, 2f0, 1f0)

        pigment = ImagePigment(image)
        @test pigment(0f0, 0f0) ≈ RGB(1f0, 2f0, 3f0)
        @test pigment(1f0, 0f0) ≈ RGB(2f0, 3f0, 1f0)
        @test pigment(0f0, 1f0) ≈ RGB(2f0, 1f0, 3f0)
        @test pigment(1f0, 1f0) ≈ RGB(3f0, 2f0, 1f0)
    end

    @testset "CheckeredPigment" begin
        color1 = RGB(1f0, 2f0, 3f0)
        color2 = RGB(10f0, 20f0, 30f0)

        pigment = CheckeredPigment{2}(color1, color2)

        # With num_of_steps == 2, the pattern should be the following:
        #
        #              (0.5, 0)
        #   (0, 0) +------+------+ (1, 0)
        #          |      |      |
        #          | col1 | col2 |
        #          |      |      |
        # (0, 0.5) +------+------+ (1, 0.5)
        #          |      |      |
        #          | col2 | col1 |
        #          |      |      |
        #   (0, 1) +------+------+ (1, 1)
        #              (0.5, 1)
        @test pigment(0.25f0, 0.25f0) ≈ color1
        @test pigment(0.75f0, 0.25f0) ≈ color2
        @test pigment(0.25f0, 0.75f0) ≈ color2
        @test pigment(0.75f0, 0.75f0) ≈ color1
    end
end
