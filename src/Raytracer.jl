# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   Raytracer.jl
# description:
#   Main package file.


"""
    Raytracer
Raytracing package for the generation of photorealistic images in Julia.
"""
module Raytracer

import Base:
    Matrix, OneTo, print_matrix,
    (+), (-), (*), (≈),
    size, zero, one, fill!, eltype,
    length, firstindex, lastindex, getindex, setindex!, iterate, axes,
    show, write,
    readline, read
import Base.Broadcast:
    BroadcastStyle, Style, Broadcasted, combine_eltypes,
    broadcastable, copy, similar
import ColorTypes:
    RGB, Fractional
import FileIO:
    save, load
import ImagePFM:
    _read
import StaticArrays:
    SVector
import LinearAlgebra:
    (⋅), (×), 
    norm, normalize
import TypedDelegation:
    @delegate_onefield, @delegate_onefield_astype, 
    @delegate_onefield_twovars, @delegate_onefield_twovars_astype

export
    RGB, HdrImage, Vec, Point,
    normalize_image, clamp_image, γ_correction,
    save, load

include("color.jl")
include("hdr_image.jl")
include("geometry.jl")

end # module Raytracer