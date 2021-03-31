module Raytracer

import Base: Exception, showerror
import Base: Matrix, OneTo, print_matrix
import Base: (+), (-), (*), (≈)
import Base: size, zero, one, fill!, eltype
import Base: length, firstindex, lastindex, getindex, setindex!, iterate, axes, show, write
import Base: readline, read
import Base.Broadcast: BroadcastStyle, Style, Broadcasted, combine_eltypes
import Base.Broadcast: broadcastable, copy, similar
import ColorTypes: RGB, Fractional
import ImageIO: DataFormat, Stream

export RGB
export HdrImage
export RaytracerException, InvalidPfmFileFormat, InvalidRgbStream
export FE, @FE_str
export normalize_image, clamp_image

include("utilities.jl")
include("exceptions.jl")
include("color.jl")
include("hdr_image.jl")

end