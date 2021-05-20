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
    SVector, MMatrix, FieldVector,
    SMatrix, @SMatrix,
    similar_type, Size
import LinearAlgebra:
    (⋅), (×), 
    norm, normalize, inv, I, Diagonal
using ProgressMeter

export
    RGB, HdrImage, 
    normalize_image, clamp_image, γ_correction, norm²,
    save, load,
    Vec, Point, Normal, Transformation, Vec2D,
    rotationX, rotationY, rotationZ,
    translation, scaling, 
    isconsistent, inverse,
    Ray, OrthogonalCamera, PerspectiveCamera,
    fire_ray, aperture_deg,
    ImageTracer, fire_all_rays,
    Shape, Sphere, Plane,
    HitRecord, World,
    ray_intersection,
    tonemapping, demo

include("color.jl")
include("hdr_image.jl")
include("geometry.jl")
include("ray.jl")
include("cameras.jl")
include("image_tracer.jl")
include("shape.jl")
include("user_utils.jl")

end # module Raytracer