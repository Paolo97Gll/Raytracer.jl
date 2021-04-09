module Raytracer

import Base: Exception, showerror
import Base: Matrix, OneTo, print_matrix
import Base: (+), (-), (*), (≈)
import Base: size, zero, one, fill!, eltype
import Base: length, firstindex, lastindex, getindex, setindex!, iterate, axes
import Base: show, write
import Base: readline, read
import Base.Broadcast: BroadcastStyle, Style, Broadcasted, combine_eltypes
import Base.Broadcast: broadcastable, copy, similar
import ColorTypes: RGB, Fractional
import FileIO: save, load
import ImagePFM: _read

export RGB
export HdrImage
export normalize_image, clamp_image, γ_correction
export save, load
export RaytracerException, InvalidRgbStream

include("color.jl")
include("hdr_image.jl")
include("exceptions.jl")

end