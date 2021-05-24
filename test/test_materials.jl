@testset "pigments" begin
    @testset "UniformPigment" begin
        color = RGB(1.0, 2.0, 3.0)
        pigment = UniformPigment(color=color)

        @test pigment(0.0, 0.0) ≈ color
        @test pigment(1.0, 0.0) ≈ color
        @test pigment(0.0, 1.0) ≈ color
        @test pigment(1.0, 1.0) ≈ color
    end

    @testset "ImagePigment" begin
        image = HdrImage(2, 2)
        image[1, 1] = RGB(1.0, 2.0, 3.0)
        image[2, 1] = RGB(2.0, 3.0, 1.0)
        image[1, 2] = RGB(2.0, 1.0, 3.0)
        image[2, 2] = RGB(3.0, 2.0, 1.0)

        pigment = ImagePigment(image)
        @test pigment(0.0, 0.0) ≈ RGB(1.0, 2.0, 3.0)
        @test pigment(1.0, 0.0) ≈ RGB(2.0, 3.0, 1.0)
        @test pigment(0.0, 1.0) ≈ RGB(2.0, 1.0, 3.0)
        @test pigment(1.0, 1.0) ≈ RGB(3.0, 2.0, 1.0)
    end

    @testset "CheckeredPigment" begin
        color1 = RGB(1.0, 2.0, 3.0)
        color2 = RGB(10.0, 20.0, 30.0)

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
        @test pigment(0.25, 0.25) ≈ color1
        @test pigment(0.75, 0.25) ≈ color2
        @test pigment(0.25, 0.75) ≈ color2
        @test pigment(0.75, 0.75) ≈ color1
    end
end