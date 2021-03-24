@testset "HDR Image" begin
    c1 = RGB(1., 2., 3.)
    c2 = RGB(4., 5., 6.)
    c3 = RGB(7., 8., 9.)
    c4 = RGB(10., 11., 12.)
    c5 = RGB(13., 14., 15.)
    c6 = RGB(16., 17., 18.)
    c7 = RGB(19., 20., 21.)
    c8 = RGB(22., 23., 24.)


    @testset "Constructors" begin
        # test constructor from matrix
        rgb_pixel_matrix = [c1 c3 c5
                            c2 c4 c6]
        image = HdrImage(rgb_pixel_matrix)
        @test all(image.pixel_matrix .=== rgb_pixel_matrix)

        # test custom constructors
        img_width, img_height = 3, 2
        rgb_zero = zero(RGB{Float32})
        rgb_zeros = [rgb_zero rgb_zero
                     rgb_zero rgb_zero
                     rgb_zero rgb_zero]

        image = HdrImage{RGB{Float32}}(img_width, img_height)
        @test image.pixel_matrix == rgb_zeros
        @test all(image.pixel_matrix .=== rgb_zeros)

        image = HdrImage(RGB{Float32}, img_width, img_height)
        @test image.pixel_matrix == rgb_zeros
        @test all(image.pixel_matrix .=== rgb_zeros)

        image = HdrImage(img_width, img_height)
        @test image.pixel_matrix == rgb_zeros
        @test all(image.pixel_matrix .=== rgb_zeros)
        @test image.pixel_matrix == HdrImage{RGB{Float32}}(img_width, img_height).pixel_matrix
        @test all(image.pixel_matrix .=== HdrImage{RGB{Float32}}(img_width, img_height).pixel_matrix)
        @test all(image.pixel_matrix .!== HdrImage{RGB{Float64}}(img_width, img_height).pixel_matrix)

        arr = Array(collect(RGB(map(Float32, 3(i-1)+1:3i)...) for i ∈ 1:img_width*img_height)) 
        image = HdrImage(arr, img_width, img_height)
        @test image.pixel_matrix == reshape(arr, img_width, img_height)
        @test all(image.pixel_matrix .=== reshape(arr, img_width, img_height))
    end


    @testset "Iterations" begin
        rgb_pixel_matrix = [c1 c3 c5
                            c2 c4 c6]
        image = HdrImage(rgb_pixel_matrix)

        # test indexing properties
        @test length(image) === 6
        @test firstindex(image) === 1
        @test lastindex(image) === 6

        # test indexing
        @test c1 == image[begin]
        @test c1 == image[1]
        @test c2 == image[2]
        @test c3 == image[3]
        @test c4 == image[4]
        @test c5 == image[5]
        @test c6 == image[end]
        @test c6 == image[6]
        @test_throws BoundsError image[7]

        @test c1 == image[1,1]
        @test c2 == image[2,1]
        @test c3 == image[1,2]
        @test c4 == image[2,2]
        @test c5 == image[1,3]
        @test c6 == image[2,3]
        @test_throws BoundsError image[0,1]
        @test_throws BoundsError image[1,0]

        @test c3 == image[CartesianIndex(1,2)]
        @test_throws BoundsError image[CartesianIndex(6,7)]

        # test set value
        _image = HdrImage{RGB{Float64}}(1, 2)
        _image[1] = c1
        _image[2] = c2
        @test _image.pixel_matrix == [c1 c2]

        # test iterability
        @test all(i == j for (i, j) in zip((c1, c2, c3, c4, c5, c6), image))
    end


    @testset "Broadcasting" begin
        a = 2
        rgb_pixel_matrix_1 = [c1 c3
                            c2 c4]
        img_1 = HdrImage(rgb_pixel_matrix_1)
        rgb_pixel_matrix_2 = [c5 c7
                            c6 c8]
        img_2 = HdrImage(rgb_pixel_matrix_2)

        # testing equivalence to custom defined methods
        @test all(img_1 .+ img_2 .== img_1.pixel_matrix + img_2.pixel_matrix)
        @test all(img_1 .- img_2 .== img_1.pixel_matrix - img_2.pixel_matrix)
        @test all(img_1 .* img_2 .== img_1.pixel_matrix .* img_2.pixel_matrix)
        @test all(a .* img_1 .== a * img_1.pixel_matrix)

        # broadcasting operators can be applied between any broadcastable type instances
        img_3 = HdrImage([c1 c1])
        @test all(((Ref(RGB(.1, .2, .3)) .+ img_3) .≈ Ref(RGB(1.1, 2.2, 3.3))))
        @test all(Ref(c1) .== img_3)

        # # it works for any operator valid for the types of the elements
        @test all((img_1 .* img_2) .≈ HdrImage([c1*c5 c3*c7; c2*c6 c4*c8]))
    end


    @testset "IO" begin
        io = IOBuffer()
        img_width, img_height = 3, 2
        rgb_pixel_matrix = [c1 c4
                            c2 c5
                            c3 c6]
        image = HdrImage{RGB{Float32}}(rgb_pixel_matrix)

        # test size
        @test size(image) == (img_width, img_height)

        # test color pretty printing
        # compact
        show(io, image)
        @test String(take!(io)) == " (1.0 2.0 3.0)  (10.0 11.0 12.0)\n (4.0 5.0 6.0)  (13.0 14.0 15.0)\n (7.0 8.0 9.0)  (16.0 17.0 18.0)"
        # extended
        show(io, "text/plain", image)
        @test String(take!(io)) == "3x2 HdrImage{RGB{Float32}}\n (1.0 2.0 3.0)  (10.0 11.0 12.0)\n (4.0 5.0 6.0)  (13.0 14.0 15.0)\n (7.0 8.0 9.0)  (16.0 17.0 18.0)"
        
        # test color write to IO
        image = HdrImage{RGB{Float32}}(3,2)
        image[1,1] = RGB(10., 20., 30.)
        image[2,1] = RGB(40., 50., 60.)
        image[3,1] = RGB(70., 80., 90.)
        image[1,2] = RGB(100., 200., 300.)
        image[2,2] = RGB(400., 500., 600.)
        image[3,2] = RGB(700., 800., 900.)
        io = IOBuffer()
        write(io, image)
        if (little_endian)
            # little endian
            expected_output = Array{UInt8}([0x50, 0x46, 0x0a, 0x33, 0x20, 0x32, 0x0a, 0x2d, 0x31, 0x2e, 0x30, 0x0a,
                                            0x00, 0x00, 0xc8, 0x42, 0x00, 0x00, 0x48, 0x43, 0x00, 0x00, 0x96, 0x43,
                                            0x00, 0x00, 0xc8, 0x43, 0x00, 0x00, 0xfa, 0x43, 0x00, 0x00, 0x16, 0x44,
                                            0x00, 0x00, 0x2f, 0x44, 0x00, 0x00, 0x48, 0x44, 0x00, 0x00, 0x61, 0x44,
                                            0x00, 0x00, 0x20, 0x41, 0x00, 0x00, 0xa0, 0x41, 0x00, 0x00, 0xf0, 0x41,
                                            0x00, 0x00, 0x20, 0x42, 0x00, 0x00, 0x48, 0x42, 0x00, 0x00, 0x70, 0x42,
                                            0x00, 0x00, 0x8c, 0x42, 0x00, 0x00, 0xa0, 0x42, 0x00, 0x00, 0xb4, 0x42])
            @test take!(io) == expected_output
        else
            # big endian
            expected_output = Array{UInt8}([0x50, 0x46, 0x0a, 0x33, 0x20, 0x32, 0x0a, 0x31, 0x2e, 0x30, 0x0a, 0x42,
                                            0xc8, 0x00, 0x00, 0x43, 0x48, 0x00, 0x00, 0x43, 0x96, 0x00, 0x00, 0x43,
                                            0xc8, 0x00, 0x00, 0x43, 0xfa, 0x00, 0x00, 0x44, 0x16, 0x00, 0x00, 0x44,
                                            0x2f, 0x00, 0x00, 0x44, 0x48, 0x00, 0x00, 0x44, 0x61, 0x00, 0x00, 0x41,
                                            0x20, 0x00, 0x00, 0x41, 0xa0, 0x00, 0x00, 0x41, 0xf0, 0x00, 0x00, 0x42,
                                            0x20, 0x00, 0x00, 0x42, 0x48, 0x00, 0x00, 0x42, 0x70, 0x00, 0x00, 0x42,
                                            0x8c, 0x00, 0x00, 0x42, 0xa0, 0x00, 0x00, 0x42, 0xb4, 0x00, 0x00])
            @test take!(io) == expected_output
        end

        # test _parse_endianness
        @test _parse_endianness("1.0") == ntoh
        @test _parse_endianness("-1.0") == ltoh
        @test_throws InvalidPfmFileFormat _parse_endianness("abba")
        @test_throws InvalidPfmFileFormat _parse_endianness("2.0")

        # test _parse_int
        @test _parse_int("12") === UInt(12)
        @test_throws InvalidPfmFileFormat _parse_int("abba")
        @test_throws InvalidPfmFileFormat _parse_int("-1")
        @test_throws InvalidPfmFileFormat _parse_int("1.0")

        # test _parse_img_size
        @test _parse_img_size("1920 1080") == UInt[1920, 1080]
        @test_throws InvalidPfmFileFormat _parse_img_size("abba 1920")
        @test_throws InvalidPfmFileFormat _parse_img_size("1920 -1080")
        @test_throws InvalidPfmFileFormat _parse_img_size("1920 1080 256")
        @test_throws InvalidPfmFileFormat _parse_img_size("1920")

        # test _read_line
        # TODO Paolo: improve tests with all the possible cases
        io = IOBuffer(b"hello\nworld")
        @test _read_line(io) == "hello\n"
        @test _read_line(io) == "world"
        @test _read_line(io) === nothing
        io = IOBuffer(b"è")
        @test_throws InvalidPfmFileFormat _read_line(io)

        # test _read_float
        # TODO Paolo: improve tests with all the possible cases
        # little endian
        io = IOBuffer()
        write(io, htol(Float32(2)))
        seekstart(io)
        @test _read_float(io, ltoh) == Float32(2)
        @test _read_float(io, ltoh) === nothing
        # big endian
        io = IOBuffer()
        write(io, hton(Float32(2)))
        seekstart(io)
        @test _read_float(io, ntoh) == Float32(2)
        @test _read_float(io, ntoh) === nothing
    end


    @testset "Other" begin
        img_width, img_height = 2, 3
        rgb_pixel_matrix = [c1 c3 c5
                            c2 c4 c6]
        image = HdrImage(rgb_pixel_matrix)

        # test eltype
        @test eltype(image) == RGB{Float64}

        # test fill!
        a = HdrImage(fill(RGB(NaN32,NaN32,NaN32), img_width, img_height))
        @test all(HdrImage(img_width, img_height) .== fill!(a, zero(RGB{Float32})))
        a = HdrImage(ones(RGB{Float32}, img_width, img_height))
        @test all(fill!(HdrImage(img_width, img_height), one(RGB{Float32})) .== a)
    end
end