# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Main package file


"""
    Raytracer
Raytracing package for the generation of photorealistic images in Julia.
"""
module Raytracer


##########
# Imports
# TODO since only import allows adding methods to a function, use import only when needed, otherwise use using


using Intervals
import Base:
    (+), (-), (*), (≈),
    Matrix, OneTo,
    axes, clamp, convert, eltype, fill!, firstindex, getindex, iterate,
    lastindex, length, one, print_matrix, rand, read, readline, setindex!, show,
    size, write, zero

import Base.Broadcast:
    BroadcastStyle, Broadcasted, Style,
    broadcastable, combine_eltypes, copy, similar

import ColorTypes:
    RGB, Fractional

import FileIO:
    save, load

import ImagePFM:
    _read

import StaticArrays:
    @SMatrix,
    FieldVector, MMatrix, SMatrix, SVector, Size,
    similar_type

import LinearAlgebra:
    (⋅), (×), 
    Diagonal, I,
    inv, norm, normalize 

import Random:
    Random.CloseOpen01, Sampler, SamplerTrivial

using ProgressMeter, Random


##########
# Exports


export
    BRDF, CheckeredPigment, DiffuseBRDF, FlatRenderer, HdrImage, HitRecord, ImagePigment,
    ImageTracer, Material, Normal, OnOffRenderer, OrthogonalCamera, PCG, PathTracer,
    PerspectiveCamera, Pigment, Plane, Point, RGB, Ray, Renderer, Shape, Sphere,
    Transformation, UniformPigment, Vec, Vec2D, World

export
    BLACK, WHITE, aperture_deg, clamp_image, create_onb_from_z, demo, fire_all_rays!, fire_ray,
    isconsistent, load, normalize, normalize_image, norm², ray_intersection, rotationX,
    rotationY, rotationZ, save, scaling, tonemapping, translation, γ_correction


###########
# Includes


include("color.jl")
include("hdr_image.jl")

include("pcg.jl")

include("geometry.jl")
include("transformations.jl")
include("ray.jl")
include("cameras.jl")
include("image_tracer.jl")
include("materials.jl")
include("shapes.jl")
include("world.jl")
include("renderers.jl")

include("user_utils.jl")


end # module Raytracer
