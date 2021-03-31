# testset variables
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
    @testset "from matrix" begin
        rgb_pixel_matrix = [c1 c3 c5
                            c2 c4 c6]
        image = HdrImage(rgb_pixel_matrix)
        @test all(image.pixel_matrix .=== rgb_pixel_matrix)
    end

    # test custom constructors
    @testset "size constructor given type" begin
        img_width, img_height = 3, 2
        rgb_zeros = zeros(RGB{Float64}, img_width, img_height)

        image = HdrImage{RGB{Float64}}(img_width, img_height)
        @test image.pixel_matrix == rgb_zeros
        @test all(image.pixel_matrix .=== rgb_zeros)
        
        # convenience alias
        image = HdrImage(RGB{Float64}, img_width, img_height)
        @test image.pixel_matrix == rgb_zeros
        @test all(image.pixel_matrix .=== rgb_zeros)
    end

    @testset "size constructor default type" begin
        img_width, img_height = 3, 2
        rgb_zeros = zeros(RGB{Float32}, img_width, img_height)
        image = HdrImage(img_width, img_height)
        @test image.pixel_matrix == rgb_zeros
        @test all(image.pixel_matrix .=== rgb_zeros)

        # test correct defaulting
        @test image.pixel_matrix == HdrImage{RGB{Float32}}(img_width, img_height).pixel_matrix
        @test all(image.pixel_matrix .=== HdrImage{RGB{Float32}}(img_width, img_height).pixel_matrix)
        @test all(image.pixel_matrix .!== HdrImage{RGB{Float64}}(img_width, img_height).pixel_matrix)
    end

    @testset "array and size" begin
        img_width, img_height = 3, 2
        arr = collect(RGB(1., 2., 3.) .+ 3.0i for i ∈ 0:img_width*img_height-1)
        image = HdrImage(arr, img_width, img_height)
        @test image.pixel_matrix == reshape(arr, img_width, img_height)
        @test all(image.pixel_matrix .=== reshape(arr, img_width, img_height))
    end

    @testset "array and shape" begin
        img_width, img_height = 3, 2
        shape = (img_width, img_height)
        arr = collect(RGB(1., 2., 3.) .+ 3.0i for i ∈ 0:img_width*img_height-1)
        image = HdrImage(arr, shape)
        @test image.pixel_matrix == reshape(arr, shape)
        @test all(image.pixel_matrix .=== reshape(arr, shape))
    end
end


@testset "Iterations" begin
    # testset variables
    rgb_pixel_matrix = [c1 c3 c5
                        c2 c4 c6]
    image = HdrImage(rgb_pixel_matrix)

    # test indexing properties
    @testset "indexing properties" begin
        @test length(image) === 6
        @test firstindex(image) === 1
        @test lastindex(image) === 6
    end

    # test get value
    @testset "get value" begin
        # linear indexing
        @test c1 == image[begin]
        @test c1 == image[1]
        @test c2 == image[2]
        @test c3 == image[3]
        @test c4 == image[4]
        @test c5 == image[5]
        @test c6 == image[end]
        @test c6 == image[6]

        # test exceptions
        @test_throws BoundsError image[7]
        
        # cartesian indexing
        @test c1 == image[1,1]
        @test c2 == image[2,1]
        @test c3 == image[1,2]
        @test c4 == image[2,2]
        @test c5 == image[1,3]
        @test c6 == image[2,3]

        @test c3 == image[CartesianIndex(1,2)]

        # test exceptions
        @test_throws BoundsError image[0,1]
        @test_throws BoundsError image[1,0]
        @test_throws BoundsError image[CartesianIndex(6,7)]
    end

    # test set value
    @testset "set value" begin
        _image = HdrImage{RGB{Float64}}(1, 2)
        _image[1] = c1
        _image[2] = c2
        @test _image.pixel_matrix == [c1 c2]
    end

    # test iterability
    @testset "iterability" begin
        @test all(i == j for (i, j) in zip((c1, c2, c3, c4, c5, c6), image))
    end
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

@testset "Tone mapping" begin
    @testset "normalize_image" begin
        img = HdrImage([RGB(  5.0,   10.0,   15.0)
                        RGB(500.0, 1000.0, 1500.0)], 2, 1)

        img = normalize_image(img, 1000.0, luminosity=100.0)
        @test all(img .≈ [RGB(0.5e2, 1.0e2, 1.5e2), RGB(0.5e4, 1.0e4, 1.5e4)])
    end

    @testset "clamp_image" begin
        img = HdrImage([RGB(0.5e1, 1.0e1, 1.5e1)
                        RGB(0.5e3, 1.0e3, 1.5e3)], 2, 1)
        img = clamp_image(img)
        @test all(0 <= col <= 1 for pix ∈ img for col ∈ pix)
    end
    
    @testset "average_luminosity" begin
        image = HdrImage([RGB(  5.0,   10.0,   15.0) RGB(500.0, 1000.0, 1500.0)])
        @test average_luminosity(image) ≈ 100.
    end

end


@testset "IO" begin
    # testset variables
    endian_f        = little_endian ? ltoh : ntoh
    test_matrix     = RGB{Float32}[RGB(1.0e1, 2.0e1, 3.0e1) RGB(1.0e2, 2.0e2, 3.0e2)
                                    RGB(4.0e1, 5.0e1, 6.0e1) RGB(4.0e2, 5.0e2, 6.0e2)
                                    RGB(7.0e1, 8.0e1, 9.0e1) RGB(7.0e2, 8.0e2, 9.0e2)]
    expected_output = open(little_endian ? "reference_le.pfm" : "reference_be.pfm") do io
                            read(io)
                        end

    # test color pretty printing
    @testset "show" begin
        io = IOBuffer()
        rgb_pixel_matrix = [c1 c4
                            c2 c5
                            c3 c6]
        image = HdrImage{RGB{Float32}}(rgb_pixel_matrix)
        # compact
        show(io, image)
        @test String(take!(io)) == " (1.0 2.0 3.0)  (10.0 11.0 12.0)\n (4.0 5.0 6.0)  (13.0 14.0 15.0)\n (7.0 8.0 9.0)  (16.0 17.0 18.0)"
        # extended
        show(io, "text/plain", image)
        @test String(take!(io)) == "3x2 HdrImage{RGB{Float32}}\n (1.0 2.0 3.0)  (10.0 11.0 12.0)\n (4.0 5.0 6.0)  (13.0 14.0 15.0)\n (7.0 8.0 9.0)  (16.0 17.0 18.0)"
    end
    
    # test color write to IO
    @testset "write" begin
        image = HdrImage(test_matrix)
        io = IOBuffer()
        write(io, FE("pfm"), image)
        @test take!(io) == expected_output
    end

    # test _parse_endianness
    @testset "_parse_endianness" begin
        @test _parse_endianness("1.0") == ntoh
        @test _parse_endianness("-1.0") == ltoh
        @test_throws InvalidPfmFileFormat _parse_endianness("abba")
        @test_throws InvalidPfmFileFormat _parse_endianness("2.0")
    end

    # test _parse_int
    @testset "_parse_int" begin
        @test _parse_int("12") === UInt(12)
        @test_throws InvalidPfmFileFormat _parse_int("abba")
        @test_throws InvalidPfmFileFormat _parse_int("-1")
        @test_throws InvalidPfmFileFormat _parse_int("1.0")
    end

    # test _parse_img_size
    @testset "_parse_img_size" begin
        @test _parse_img_size("1920 1080") == UInt[1920, 1080]

        # test exceptions
        @test_throws InvalidPfmFileFormat _parse_img_size("abba 1920")
        @test_throws InvalidPfmFileFormat _parse_img_size("1920 -1080")
        @test_throws InvalidPfmFileFormat _parse_img_size("1920 1080 256")
        @test_throws InvalidPfmFileFormat _parse_img_size("1920")
    end

    # test _read_line
    # TODO Paolo: improve tests with all the possible cases
    @testset "_read_line" begin
        io = IOBuffer(b"hello\nworld")
        @test _read_line(io) == "hello\n"
        @test _read_line(io) == "world"
        @test _read_line(io) === nothing
        
        # test exceptions
        io = IOBuffer(b"è")
        @test_throws InvalidPfmFileFormat _read_line(io)
    end

    # test _read_matrix
    @testset "_read_matrix" begin
        io = IOBuffer()
        write(io, test_matrix...)
        seekstart(io)
        @test all(_read_matrix(io, eltype(test_matrix), size(test_matrix)...) .== test_matrix)
        
        # test exceptions
        io = IOBuffer()
        write(io, test_matrix[begin:end-1])
        seekstart(io)
        @test_throws EOFError _read_matrix(io, eltype(test_matrix), size(test_matrix)...)
    end

    # test read(io, ::FE"pfm")
    @testset "read" begin
        img = read(IOBuffer(expected_output), FE("pfm"))
        @test size(img) == size(test_matrix)
        @test all(img .== test_matrix)
        
        # test exceptions
        @test_throws InvalidPfmFileFormat read(IOBuffer(b"PF\n3 2\n-1.0\nstop"), FE("pfm"))
    end

    #test write/read compatibility
    @testset "write/read compatibility" begin
        img = HdrImage(test_matrix)
        io = IOBuffer()
        write(io, FE("pfm"), img)
        seekstart(io)
        @test all(read(io, FE("pfm")) .== img)
    end
end


@testset "Other" begin
    # testset variables
    img_width, img_height = 2, 3
    rgb_pixel_matrix = [c1 c3 c5
                        c2 c4 c6]
    image = HdrImage(rgb_pixel_matrix)

    # test eltype
    @testset "eltype" begin
        @test eltype(image) == RGB{Float64}
    end

    # test fill!
    @testset "fill!" begin
        a = HdrImage(fill(RGB(NaN32,NaN32,NaN32), img_width, img_height))
        @test all(HdrImage(img_width, img_height) .== fill!(a, zero(RGB{Float32})))

        a = HdrImage(ones(RGB{Float32}, img_width, img_height))
        @test all(fill!(HdrImage(img_width, img_height), one(RGB{Float32})) .== a)
    end

    # test size
    @testset "size" begin
        @test size(image) == (img_width, img_height)
    end
end