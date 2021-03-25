@testset "Other" begin
    # test little_endian
    if (little_endian)
        # little endian
        @test reinterpret(UInt32, 1.0f0) == 0x3f800000
    else
        # big endian
        @test reinterpret(UInt32, 1.0f0) == 0x0000803f
    end

    #test @FE_str
    sym = :test
    str = String(sym)
    @test FE(str) == FE{sym}() 
    @test (@FE_str test) == FE"test"
    @test typeof(FE(str)) == FE"test"

end