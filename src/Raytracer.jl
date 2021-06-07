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


import Base:
    (+), (-), (*), (≈),
    Matrix, OneTo,
    axes, clamp, convert, eltype, fill!, firstindex, getindex, iterate,
    lastindex, length, one, print_matrix, rand, read, readline, setindex!, show,
    size, write, zero

import Base.Broadcast:
    BroadcastStyle, Broadcasted, Style,
    broadcastable, combine_eltypes, copy, similar

using ColorTypes:
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

using Random
import Random:
    Random.CloseOpen01, Sampler, SamplerTrivial

using Intervals, ProgressMeter


##########
# Exports

export # Rendering
    RGB, 
    HdrImage,
    Camera, 
        PerspectiveCamera, OrthogonalCamera,
        aperture_deg,
        fire_ray,
    ImageTracer,
        fire_all_rays!,
    Ray,
    HitRecord,
    Pigment, 
        UniformPigment,
        CheckeredPigment,
        ImagePigment,
    BRDF, 
        DiffuseBRDF, SpecularBRDF,
    Material, 
    Renderer, 
        OnOffRenderer, FlatRenderer, PathTracer

export # Scene
    Normal, Vec, 
        normalize,
        norm²,
        create_onb_from_z,
    Point,
    Vec2D,
    Transformation,
        isconsistent, 
        rotationX, rotationY, rotationZ,
        scaling, translation,
    Shape,
        Sphere, Plane,
        ray_intersection,
    World

export # Random number generation
    PCG

export # High level API
    demo, tonemapping

export # image tools
    clamp_image, normalize_image, γ_correction, load, save

export # Colors
    BLACK, WHITE,
    RED, GREEN, BLUE, 
    CYAN, MAGENTA, YELLOW 


###########
# Includes


include("color.jl")
include("hdr_image.jl")

include("pcg.jl")

include("geometry.jl")
include("transformations.jl")
include("ray.jl")
include("cameras.jl")
include("materials.jl")
include("shapes.jl")
include("world.jl")
include("renderers.jl")
include("image_tracer.jl")

include("user_utils.jl")


end # module Raytracer
