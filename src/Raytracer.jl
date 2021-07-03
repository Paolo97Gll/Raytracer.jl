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
    (+), (-), (*), (≈), (==),
    Matrix, OneTo,
    axes, clamp, convert, eltype, fill!, firstindex, getindex, iterate,
    lastindex, length, one, print_matrix, rand, read, readline, setindex!, show,
    size, write, zero,
    union, intersect, setdiff,
    isless, isequal

import Base.Broadcast:
    BroadcastStyle, Broadcasted, Style,
    broadcastable, combine_eltypes, copy, similar

using ColorTypes:
    RGB, Fractional

using FileIO:
    File, @format_str, query
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
        HitOrMiss,
    Pigment,
        UniformPigment,
        CheckeredPigment,
        ImagePigment,
    BRDF,
        DiffuseBRDF, SpecularBRDF,
        at,
    Material,
    Renderer,
        OnOffRenderer, FlatRenderer, PathTracer, PointLightRenderer

export # Scene
    Normal, Vec,
        normalize,
        norm,
        norm²,
        create_onb_from_z,
        NORMAL_X, NORMAL_Y, NORMAL_Z,
        VEC_X, VEC_Y, VEC_Z,
        NORMAL_X_false, NORMAL_Y_false, NORMAL_Z_false,
    Point,
        convert,
        ORIGIN,
    Vec2D,
    Transformation,
        isconsistent,
        rotationX, rotationY, rotationZ,
        scaling, translation,
    Shape,
        Sphere, Plane, Cube, Cylinder, Cone,
        CSG,
            UnionCSG,
            IntersectionCSG,
            DiffCSG,
            FusionCSG,
        fuse,
        Rule,
            UniteRule,
            IntersectRule,
            DiffRule,
            FuseRule,
        get_t, get_all_ts, get_uv, get_normal,
        ray_intersection, all_ray_intersections, quick_ray_intersection,
    World,
        is_point_visible,
    PointLight,
    Lights

export # Random number generation
    PCG

export # High level API
    tonemapping, render, render_from_script

export # image tools
    clamp_image, normalize_image, γ_correction, load, save

export # Colors
    BLACK, WHITE,
    RED, GREEN, BLUE,
    CYAN, MAGENTA, YELLOW


###########
# Includes


include("colors.jl")
include("hdrimage.jl")

include("pcg.jl")

include("geometry.jl")
include("transformations.jl")
include("ray.jl")
include("cameras.jl")
include("materials.jl")
include("lights.jl")
include("hitrecord.jl")
include("shapes.jl")
include("world.jl")
include("renderers.jl")
include("imagetracer.jl")

include("interpreter.jl")

using .Interpreter:
    print_subsequent_lexer_exceptions,
    Scene,
    open_stream,
    parse_variables_from_string,
    InterpreterException,
    parse_scene,
    SourceLocation,
    UndefinedSetting

include("user_utils.jl")


end # module Raytracer
