@testset "Other" begin
    # test little_endian
    if (little_endian)
        # little endian
        @test reinterpret(UInt32, 1.0f0) == 0x3f800000
    else
        # big endian
        @test reinterpret(UInt32, 1.0f0) == 0x0000803f
    end
end