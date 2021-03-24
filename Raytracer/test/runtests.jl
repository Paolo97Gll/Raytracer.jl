using Raytracer
using Test

using Raytracer: little_endian, HdrImage, InvalidPfmFileFormat, _parse_endianness
import ColorTypes.RGB

include("test_color.jl")
include("test_hdr_image.jl")
include("test_utilities.jl")