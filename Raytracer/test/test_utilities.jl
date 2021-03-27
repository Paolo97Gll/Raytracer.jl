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

    # test _read_float
    # TODO Paolo: improve tests with all the possible cases
    @testset "_read_type" begin
        io = IOBuffer()
        write(io, Float32(2))
        seekstart(io)
        @test _read_type{Float32}(io) == Float32(2)
        @test _read_type{Float32}(io) === nothing
    end

    # test _TypeStream interface
    @testset "_TypeStream" begin
        io = IOBuffer()
        test_float = (1.0f0, 2.0f0, 3.0f0, 4.0f0)
        write(io, test_float...)
        seekstart(io)
        @test all((_TypeStream(io, Float32, 3)...,) .== test_float[1:3])
        
        # test exceptions
        @test_throws EOFError (_FloatStream(io, Float32, 3)...,)
    end

end