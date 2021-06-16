# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

########
# Plane


"""
    Plane <: SimpleShape

A [`SimpleShape`](@ref) representing an infinite plane.

# Members

- `transformation::Transformation`: the `Transformation` associated with the plane.
- `material::Material`: the [`Material`](@ref) of the plane.
"""
Base.@kwdef struct Plane <: SimpleShape
    transformation::Transformation = Transformation()
    material::Material = Material()
end

@doc """
    Plane(transformation::Transformation, material::Material)

Constructor for a [`Plane`](@ref) instance.
""" Plane(::Transformation, ::Material)

@doc """
    Plane(transformation::Transformation = Transformation(),
           material::Material = Material())

Constructor for a [`Plane`](@ref) instance.
""" Plane(; ::Transformation, ::Material)

function get_all_ts(::Type{Plane}, ray::Ray)
    abs(ray.dir.z) >= 1f-5 && ((t = -ray.origin.v[3] / ray.dir.z) |> isfinite) ? [t] : Vector{Float32}()
end

function get_t(::Type{Plane}, ray::Ray)
    abs(ray.dir.z) < 1f-5 && return Inf32
    t = -ray.origin.v[3] / ray.dir.z
    ray.tmin < t < ray.tmax ? t : Inf32
end

function get_uv(::Type{Plane}, point::Point)
    point.v[1:2] - floor.(point.v[1:2]) |> Vec2D
end

function get_normal(::Type{Plane}, point::Point, ray::Ray)
    -sign(ray.dir.z) * NORMAL_Z
end
