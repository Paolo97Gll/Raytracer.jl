module Raytracer

import ColorTypes: RGB
import Base: Matrix, OneTo
import Base: (+), (-), (*), (≈) 
import Base: size, zero, eltype, length, firstindex, lastindex, getindex, getindex, iterate, axes, show
import Base.Broadcast: BroadcastStyle, Style, Broadcasted
import Base.Broadcast: broadcastable, copy, similar

include("color.jl")
include("hdr_image.jl")

end