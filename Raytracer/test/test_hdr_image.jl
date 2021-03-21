@testset "HDR Image" begin
    @testset "Constructors" begin
        width, height = 3, 2
        rgb_zero = zero(RGB{Float32})
        rgb_zeros = [rgb_zero rgb_zero rgb_zero
                     rgb_zero rgb_zero rgb_zero]

        @test HdrImage{RGB{Float32}}(width, height).pixel_matrix == rgb_zeros
        @test HdrImage(RGB{Float32}, width, height).pixel_matrix == rgb_zeros
        @test HdrImage(width, height).pixel_matrix == rgb_zeros
        @test HdrImage(width, height).pixel_matrix == HdrImage{RGB{Float32}}(width, height).pixel_matrix
        @test eltype(HdrImage(width, height).pixel_matrix) == eltype(HdrImage{RGB{Float32}}(width, height).pixel_matrix)
        @test eltype(HdrImage(width, height).pixel_matrix) != eltype(HdrImage{RGB{Float64}}(width, height).pixel_matrix)
    end

    @testset "Iterations" begin
        # TODO Paolo: Iterations tests
    end


    @testset "Broadcasting" begin
        # TODO Paolo: Broadcasting tests
    end


    @testset "IO" begin
        # TODO Paolo: IO tests
    end


    @testset "Other" begin
        width, height = 3, 2
        a = HdrImage(fill(RGB(NaN32,NaN32,NaN32), height, width))
        @test all(HdrImage(width, height) .== fill!(a, zero(RGB{Float32})))
        a = HdrImage(ones(RGB{Float32}, height, width))
        @test all(fill!(HdrImage(width, height), one(RGB{Float32})) .== a)
        # TODO Paolo: Other tests
    end
end