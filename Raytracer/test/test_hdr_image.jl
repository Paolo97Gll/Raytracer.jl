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
    end


    @testset "Broadcasting" begin
    end


    @testset "IO" begin
    end


    @testset "Other" begin
    end
end