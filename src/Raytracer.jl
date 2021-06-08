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
        luminosity, clamp, γ_correction,
    HdrImage,
        luminosity, clamp, γ_correction,
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
        OnOffRenderer, FlatRenderer, PathTracer, PointLightRenderer

export # Scene
    Normal, Vec,
        normalize,
        norm,
        norm²,
        create_onb_from_z,
    Point,
        convert,
    Vec2D,
    Transformation,
        isconsistent,
        rotationX, rotationY, rotationZ,
        scaling, translation,
    Shape,
        Sphere, Plane, Cube,
        get_t, get_uv, get_normal,
        ray_intersection, quick_ray_intersection,
    World,
        is_point_visible,
    PointLight,
    Lights

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


include("colors.jl")
include("hdr_image.jl")

include("pcg.jl")

include("geometry.jl")
include("transformations.jl")
include("ray.jl")
include("cameras.jl")
include("materials.jl")
include("shapes.jl")
include("world.jl")
include("lights.jl")
include("renderers.jl")
include("image_tracer.jl")

include("user_utils.jl")


end # module Raytracer
