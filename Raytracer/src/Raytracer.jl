module Raytracer

import ColorTypes: RGB
import Base: Matrix, OneTo
import Base: (+), (-), (*), (≈) 
import Base: size, zero, eltype, length, firstindex, lastindex, getindex, getindex, iterate, axes
import Base.Broadcast: BroadcastStyle
import Base.Broadcast: broadcastable, copy

include("color.jl")
include("hdr_image.jl")

end