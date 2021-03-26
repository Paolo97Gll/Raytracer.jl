@testset "Other" begin
    # test little_endian
    @testset "little_endian" begin
        @test reinterpret(UInt32, 1.0f0) == (little_endian ? 0x3f800000 : 0x0000803f)
    end

    #test @FE_str
    @testset "@FE_str" begin
        sym = :test
        str = String(sym)
        @test FE(str) == FE{sym}() 
        @test (@FE_str test) == FE"test"
        @test typeof(FE(str)) == FE"test"
    end

end