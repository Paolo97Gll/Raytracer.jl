# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

#########
# Sphere

"""
    struct Sphere <: SimpleShape

A [`SimpleShape`](@ref) representing a sphere.

This is a unitary sphere centered in the origin. A generic sphere can be specified by applying a [`Transformation`](@ref).

# Members

- `transformation::Transformation`: the `Transformation` associated with the sphere.
- `material::Material`: the [`Material`](@ref) of the spere.
"""
Base.@kwdef struct Sphere <: SimpleShape
    transformation::Transformation = Transformation()
    material::Material = Material()
end

@doc """
    Sphere(transformation::Transformation, material::Material)

Constructor for a [`Sphere`](@ref) instance.
""" Sphere(::Transformation, ::Material)

@doc """
    Sphere(transformation::Transformation = Transformation(),
           material::Material = Material())

Constructor for a [`Sphere`](@ref) instance.
""" Sphere(; ::Transformation, ::Material)

function get_all_ts(::Type{Sphere}, ray::Ray)
    # compute intersection
    origin_vec = convert(Vec, ray.origin)
    a = norm²(ray.dir)
    b = 2f0 * origin_vec ⋅ ray.dir
    c = norm²(origin_vec) - 1f0
    Δ = b^2 - 4f0 * a * c
    Δ < 0 && return Vector{Float32}()
    sqrt_Δ = sqrt(Δ)
    t_1 = (-b - sqrt_Δ) / (2f0 * a)
    t_2 = (-b + sqrt_Δ) / (2f0 * a)

    # @assert isfinite(t_1)
    # @assert isfinite(t_2)

    return [t_1, t_2]
end

function get_t(::Type{Sphere}, ray::Ray)
    # compute intersection
    origin_vec = convert(Vec, ray.origin)
    a = norm²(ray.dir)
    b = 2f0 * origin_vec ⋅ ray.dir
    c = norm²(origin_vec) - 1f0
    Δ = b^2 - 4f0 * a * c
    Δ < 0 && return Inf32
    sqrt_Δ = sqrt(Δ)
    t_1 = (-b - sqrt_Δ) / (2f0 * a)
    t_2 = (-b + sqrt_Δ) / (2f0 * a)
    # nearest point
    if ray.tmin < t_1 < ray.tmax
        return t_1
    elseif ray.tmin < t_2 < ray.tmax
        return t_2
    else
        return Inf32
    end
end

function get_uv(::Type{Sphere}, point::Point)
    u = atan(point[2], point[1]) / (2f0 * π)
    u = u >= 0 ? u : u+1f0
    v = acos(clamp(point[3], -1f0, 1f0)) / π
    Vec2D(u, v)
end

function get_normal(::Type{Sphere}, point::Point, ray::Ray)
    normal = convert(Normal, point) |> normalize
    (normal ⋅ ray.dir < 0) ? normal : -normal
end
