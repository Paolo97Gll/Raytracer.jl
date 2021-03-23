module Raytracer

import ColorTypes: RGB, Fractional
import Base: Matrix, OneTo, print_matrix
import Base: (+), (-), (*), (≈)
import Base: size, zero, one, fill!, eltype
import Base: length, firstindex, lastindex, getindex, setindex!, iterate, axes, show, write
import Base.Broadcast: BroadcastStyle, Style, Broadcasted, combine_eltypes
import Base.Broadcast: broadcastable, copy, similar

include("color.jl")
include("hdr_image.jl")
include("utilities.jl")

end