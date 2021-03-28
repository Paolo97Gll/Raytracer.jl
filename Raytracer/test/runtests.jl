using Raytracer
using Test, Documenter

using Raytracer: little_endian, _read_line, _read_type, _parse_endianness, _parse_int, _parse_img_size, _TypeStream, _read_matrix

DocMeta.setdocmeta!(Raytracer, :DocTestSetup, :(using Raytracer); recursive=true)
@testset "doctest" begin
    doctest(Raytracer, manual = false)
end

@testset "Color" begin
    include("test_color.jl")
end

@testset "HDR Image" begin
    include("test_hdr_image.jl")
end

@testset "Other" begin
    include("test_utilities.jl")
end