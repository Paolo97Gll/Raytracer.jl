using Raytracer
using Test

using Raytracer: little_endian, _read_line, _read_float, _parse_endianness, _parse_int, _parse_img_size, _FloatStream

include("test_color.jl")
include("test_hdr_image.jl")
include("test_utilities.jl")