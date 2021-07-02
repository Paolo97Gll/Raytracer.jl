# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Implementation of Pigments and BRDFs


#####################################################################


"""
    Pigment

This abstract type represents a pigment, i.e., a function that associates a color with
each point on a parametric surface ``(u,v)``.

Each subtype of this type must be a callable like `(p::Pigment)(uv::Vec2D)` and must return
the color of the surface as a `RGB{Float32}` in a given [`Vec2D`](@ref) point.

See also: [`UniformPigment`](@ref), [`CheckeredPigment`](@ref), [`ImagePigment`](@ref)
"""
abstract type Pigment end

"""
    (p::Pigment)(uv::Vec2D)

Return the color of the surface in the given point [`Vec2D`](@ref).
"""
function (p::Pigment)(uv::Vec2D)
    p(uv...)
end


#################
# UniformPigment


"""
    UniformPigment <: Pigment

A uniform [`Pigment`](@ref) over the whole surface.
"""
Base.@kwdef struct UniformPigment <: Pigment
    color::RGB{Float32} = WHITE
end

@doc """
    UniformPigment(color::RGB{Float32})

Constructor for a [`UniformPigment`](@ref) instance.
""" UniformPigment(::RGB{Float32})

@doc """
    UniformPigment(; color::RGB{Float32} = WHITE)

Constructor for a [`UniformPigment`](@ref) instance.
""" UniformPigment(; ::RGB{Float32})

"""
    (up::UniformPigment)(u::Float32, v::Float32)

Return the color of the surface in the given point ``(u,v)``.
"""
(up::UniformPigment)(::Float32, ::Float32) = up.color


###################
# CheckeredPigment


"""
    CheckeredPigment{N} <: Pigment

A checkered [`Pigment`](@ref). The number of rows/columns in the checkered pattern is tunable with `N`,
but you cannot have a different number of repetitions along the u/v directions.
"""
struct CheckeredPigment{N} <: Pigment
    color_on::RGB{Float32}
    color_off::RGB{Float32}

    function CheckeredPigment{N}(color_on::RGB{Float32}, color_off::RGB{Float32}) where {N}
        @assert isa(N, Integer)
        new{N}(color_on, color_off)
    end
end

@doc """
    CheckeredPigment{N}(color_on::RGB{Float32}, color_off::RGB{Float32}) where {N}

Constructor for a [`CheckeredPigment`](@ref) instance.
""" CheckeredPigment{N}(::RGB{Float32}, ::RGB{Float32}) where {N}

"""
    CheckeredPigment{N}(; color_on::RGB{Float32} = WHITE,
                      color_off::RGB{Float32} = BLACK) where {N}

Constructor for a [`CheckeredPigment`](@ref) instance.
"""
function CheckeredPigment{N}(; color_on::RGB{Float32} = WHITE, color_off::RGB{Float32} = BLACK) where {N}
    CheckeredPigment{N}(color_on, color_off)
end

"""
    CheckeredPigment(; N::Int = 2, color_on::RGB{Float32} = WHITE,
                      color_off::RGB{Float32} = BLACK) where {N}

Constructor for a [`CheckeredPigment`](@ref) instance.
"""
function CheckeredPigment(; N::Int = 2, color_on::RGB{Float32} = WHITE, color_off::RGB{Float32} = BLACK)
    CheckeredPigment{N}(color_on, color_off)
end

"""
    (cp::CheckeredPigment{N})(u::Float32, v::Float32) where {N}

Return the color of the surface in the given point ``(u,v)``.
"""
function (cp::CheckeredPigment{N})(u::Float32, v::Float32) where {N}
    ceil(u*N)%2 == ceil(v*N)%2 ? cp.color_on : cp.color_off
end


###############
# ImagePigment


"""
    ImagePigment <: Pigment

A textured [`Pigment`](@ref). The texture is given through a PFM image.
"""
struct ImagePigment <: Pigment
    image::HdrImage
end

@doc """
    ImagePigment(image::HdrImage)

Constructor for a [`ImagePigment`](@ref) instance.
""" ImagePigment(::HdrImage)

"""
    ImagePigment(; image::HdrImage = HdrImage(1, 1))

Constructor for a [`ImagePigment`](@ref) instance.
"""
function ImagePigment(; image::HdrImage = HdrImage(1, 1))
    ImagePigment(image)
end

"""
    (ip::ImagePigment)(u::Float32, v::Float32)

Return the color of the surface in the given point ``(u,v)``.
"""
function (ip::ImagePigment)(u::Float32, v::Float32)
    size_row, size_col = size(ip.image)
    f(x) = iszero(x) ? x + 1 : x
    row = u * size_row |> ceil |> Int |> f
    col = v * size_col |> ceil |> Int |> f
    ip.image[row, col]
end


#####################################################################


"""
    BRDF

An abstract type representing a Bidirectional Reflectance Distribution Function.

Each subtype of this type must include a field `pigment::`[`Pigment`](@ref) storing the pigment on which the BRDF operates.
Each subtype of this type must implement an `at(::NewBRDF, ::Normal, in_dir::Vec, out_dir::Vec, uv::Vec2D)` function, where `NewBRDF` should be swubstituted with your new type name. This function evaluates the BRDF of a point with given normal, input and output directions and uv coordinates (which are used to evaluate)
        
See also: [`DiffuseBRDF`](@ref), [`SpecularBRDF`](@ref),
"""
abstract type BRDF end


##############
# DiffuseBRDF


"""
    DiffuseBRDF <: BRDF

A class representing an ideal diffuse [`BRDF`](@ref) (also called "Lambertian").
"""
Base.@kwdef struct DiffuseBRDF <: BRDF
    pigment::Pigment = UniformPigment()
end

@doc """
    DiffuseBRDF(pigment::Pigment, reflectance::Float32)

Constructor for a [`DiffuseBRDF`](@ref) instance.
""" DiffuseBRDF(::Pigment, ::Float32)

@doc """
    DiffuseBRDF(; pigment::Pigment = UniformPigment(),
                  reflectance::Float32 = 1f0)

Constructor for a [`DiffuseBRDF`](@ref) instance.
""" DiffuseBRDF(; ::Pigment, ::Float32)

"""
    at(brdf::DiffuseBRDF, normal::Normal, in_dir::Vec, out_dir::Vec, uv::Vec2D)

Get the radiance, given a point `uv` ([`Vec2D`](@ref)) on the surface with a [`DiffuseBRDF`](@ref)., an incoming
direction `in_dir` and outcoming direction ([`Vec`](@ref)), a `normal` of the surface point ([`Normal`](@ref)).
"""
function at(brdf::DiffuseBRDF, #=normal=#::Normal, #=in_dir=#::Vec, #=out_dir=#::Vec, uv::Vec2D)
    brdf.pigment(uv) * (1f0 / π)
end

"""
    scatter_ray(::DiffuseBRDF, pcg::PCG, incoming_dir::Vec, interaction_point::Point, normal::Normal, depth::Int)

Scatter a ray on the surface.
"""
function scatter_ray(::DiffuseBRDF, pcg::PCG, incoming_dir::Vec,
                     interaction_point::Point, normal::Normal, depth::Int)
    e1, e2, e3 = create_onb_from_z(normal)
    cos_θ_sq = rand(pcg, Float32)
    cos_θ = sqrt(cos_θ_sq)
    φ = 2f0 * π * rand(pcg, Float32)

    Ray(
        interaction_point,
        e1 * cos(φ) * cos_θ + e2 * sin(φ) * cos_θ + e3 * sqrt(1f0 - cos_θ_sq),
        1.0f-3,
        Inf32,
        depth
    )
end


###############
# SpecularBRDF


"""
    SpecularBRDF <: BRDF

A class representing an ideal mirror [`BRDF`](@ref).
"""
Base.@kwdef struct SpecularBRDF <: BRDF
    pigment::Pigment = UniformPigment()
    threshold_angle_rad::Float32 = π / 1800f0
end

@doc """
    SpecularBRDF(pigment::Pigment, threshold_angle_rad::Float32)

Constructor for a [`SpecularBRDF`](@ref) instance.
""" SpecularBRDF(::Pigment, ::Float32)

@doc """
    SpecularBRDF(; pigment::Pigment = UniformPigment(),
                   threshold_angle_rad::Float32 = π / 1800f0)

Constructor for a [`SpecularBRDF`](@ref) instance.
""" SpecularBRDF(; ::Pigment, ::Float32)

"""
    at(brdf::SpecularBRDF, normal::Normal, in_dir::Vec, out_dir::Vec, uv::Vec2D)

Get the radiance, given a point `uv` ([`Vec2D`](@ref)) on the surface with a [`SpecularBRDF`](@ref)., an incoming
direction `in_dir` and outcoming direction ([`Vec`](@ref)), a `normal` of the surface point ([`Normal`](@ref)).
"""
function at(brdf::SpecularBRDF, normal::Normal, in_dir::Vec, out_dir::Vec, uv::Vec2D)
    θ_in = normalized_dot(normal, in_dir) |> acos
    θ_out = normalized_dot(normal, out_dir) |> acos
    abs(θ_in - θ_out) < brdf.threshold_angle_rad < brdf.threshold_angle_rad ? brdf.pigment(uv) : BLACK
end

"""
    scatter_ray(::SpecularBRDF, pcg::PCG, incoming_dir::Vec, interaction_point::Point, normal::Normal, depth::Int)

Scatter a ray on the surface.
"""
function scatter_ray(::SpecularBRDF, pcg::PCG, incoming_dir::Vec,
                     interaction_point::Point, normal::Normal, depth::Int)
    ray_dir = normalize(incoming_dir)
    normal = normalize(normal)

    Ray(interaction_point,
        ray_dir - normal * 2f0 * (normal ⋅ ray_dir),
        1f-3,
        Inf32,
        depth)
end


#####################################################################


"""
    Material

A material with a `brdf::BRDF` ([`BRDF`](@ref)) and and `emitted_radiance::Pigment` ([`Pigment`](@ref)).
"""
Base.@kwdef struct Material
    brdf::BRDF = DiffuseBRDF()
    emitted_radiance::Pigment = UniformPigment(BLACK)
end

@doc """
    Material(brdf::BRDF, emitted_radiance::Pigment)

Constructor for a [`Material`](@ref) instance.
""" Material(::BRDF, ::Pigment)

@doc """
    Material(; brdf::BRDF = DiffuseBRDF(), emitted_radiance::Pigment = UniformPigment(BLACK))

Constructor for a [`Material`](@ref) instance.
""" Material(; ::BRDF, ::Pigment)
