@testset "HDR Image" begin
    @testset "Constructors" begin
        # test custom constructors
        img_width, img_height = 2, 3
        rgb_zero = zero(RGB{Float32})
        rgb_zeros = [rgb_zero rgb_zero rgb_zero
                     rgb_zero rgb_zero rgb_zero]
        @test all(HdrImage{RGB{Float32}}(img_width, img_height).pixel_matrix .=== rgb_zeros)
        @test all(HdrImage(RGB{Float32}, img_width, img_height).pixel_matrix .=== rgb_zeros)
        @test all(HdrImage(img_width, img_height).pixel_matrix .=== rgb_zeros)
        @test all(HdrImage(img_width, img_height) .=== HdrImage{RGB{Float32}}(img_width, img_height))
        @test all(HdrImage(img_width, img_height) .!== HdrImage{RGB{Float64}}(img_width, img_height))

        # test constructor from matrix
        rgb_pixel_matrix = [RGB(1., 2., 3.) RGB(10., 11., 12.)
                            RGB(4., 5., 6.) RGB(13., 14., 15.)
                            RGB(7., 8., 9.) RGB(16., 17., 18.)]
        @test all(HdrImage(rgb_pixel_matrix).pixel_matrix .=== rgb_pixel_matrix)
    end


    @testset "Iterations" begin
        c1 = RGB(1., 2., 3.)
        c2 = RGB(4., 5., 6.)
        c3 = RGB(7., 8., 9.)
        c4 = RGB(10., 11., 12.)
        c5 = RGB(13., 14., 15.)
        c6 = RGB(16., 17., 18.)
        rgb_pixel_matrix = [c1 c4
                            c2 c5
                            c3 c6]
        image = HdrImage(rgb_pixel_matrix)

        # test indexing
        @test c1 == image[begin] == image[1]
        @test c2 == image[2]
        @test c3 == image[3]
        @test c4 == image[4]
        @test c5 == image[5]
        @test c6 == image[end] == image[6]
        @test_throws BoundsError image[7]

        # test iterability
        @test all(i == j for (i, j) in zip((c1, c2, c3, c4, c5, c6), image))
    end


    @testset "Broadcasting" begin
        # TODO Paolo: Broadcasting tests
    end


    @testset "IO" begin
        # TODO Paolo: IO tests
    end


    @testset "Other" begin
        img_width, img_height = 2, 3

        # test fill!
        a = HdrImage(fill(RGB(NaN32,NaN32,NaN32), img_width, img_height))
        @test all(HdrImage(img_width, img_height) .== fill!(a, zero(RGB{Float32})))
        a = HdrImage(ones(RGB{Float32}, img_width, img_height))
        @test all(fill!(HdrImage(img_width, img_height), one(RGB{Float32})) .== a)
        
        # TODO Paolo: Other tests
    end
end