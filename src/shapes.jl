# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Implementation of the abstract type Shape and the derivative concrete types


"""
    Shape

An abstract type representing a shape.

See also: [`Sphere`](@ref), [`Plane`](@ref)
"""
abstract type Shape end

function show(io::IO, ::MIME"text/plain", s::T) where {T <: Shape}
    print(io, T)
    fns = fieldnames(T)
    n = maximum(fns .|> String .|> length)
    for fieldname ∈ fns
        println(io)
        print(io, " ↳ ", rpad(fieldname, n), " = ", getfield(s, fieldname))
    end
end


#########
# Sphere


"""
    Sphere <: Shape

A [`Shape`](@ref) representing a sphere.

This is a unitary sphere centered in the origin. A generic sphere can be specified by applying a [`Transformation`](@ref).

# Fields

- `transformation::Transformation`: the `Transformation` associated with the sphere.
- `material::Material`: the [`Material`](@ref) of the spere.

See also: [`ray_intersection(::Ray, ::Sphere)`](@ref)
"""
Base.@kwdef struct Sphere <: Shape
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

"""
    ray_intersection(ray::Ray, s::Sphere)

Return an [`HitRecord`](@ref) of the nearest ray intersection with the given [`Sphere`](@ref).

If none exists, return `nothing`.
"""
function ray_intersection(ray::Ray, s::Sphere)
    inv_ray = inv(s.transformation) * ray
    # compute intersection
    origin_vec = convert(Vec, inv_ray.origin)
    a = norm²(inv_ray.dir)
    b = 2f0 * origin_vec ⋅ inv_ray.dir
    c = norm²(origin_vec) - 1f0
    Δ = b^2 - 4f0 * a * c
    Δ < 0f0 && return nothing
    sqrt_Δ = sqrt(Δ)
    t_1 = (-b - sqrt_Δ) / (2f0 * a)
    t_2 = (-b + sqrt_Δ) / (2f0 * a)
    # nearest point
    if (t_1 > inv_ray.tmin) && (t_1 < inv_ray.tmax)
        hit_t = t_1
    elseif (t_2 > inv_ray.tmin) && (t_2 < inv_ray.tmax)
        hit_t = t_2
    else
        return nothing
    end
    hit_point = inv_ray(hit_t)
    # generate HitRecord
    world_point = s.transformation * hit_point
    normal = convert(Normal, hit_point)
    normal = s.transformation * ((normal ⋅ ray.dir < 0f0) ? normal : -normal)
    u = atan(hit_point[2], hit_point[1]) / (2f0 * π)
    u = u >= 0f0 ? u : u+1f0
    v = acos(clamp(hit_point[3], -1f0, 1f0)) / π
    surface_point = Vec2D(u, v)
    HitRecord(world_point, normal, surface_point, hit_t, ray, s.material)
end

"""
    quick_ray_intersection(ray::Ray, s::Sphere)

Tells if a [`Ray`](@ref) intersect a [`Sphere`](@ref) or not.
"""
function quick_ray_intersection(ray::Ray, s::Sphere)
    inv_ray = inv(s.transformation) * ray
    origin_vec = convert(Vec, inv_ray.origin)
    a = norm²(inv_ray.dir)
    b = 2f0 * origin_vec ⋅ inv_ray.dir
    c = norm²(origin_vec) - 1f0
    Δ = b^2 - 4f0 * a * c
    Δ < 0f0 && return false
    sqrt_Δ = sqrt(Δ)
    (inv_ray.tmin < (-b-sqrt_Δ)/(2f0*a) < inv_ray.tmax) || (inv_ray.tmin < (-b+sqrt_Δ)/(2f0*a) < inv_ray.tmax)
end


########
# Plane


"""
    Plane <: Shape

A [`Shape`](@ref) representing an infinite plane.

# Fields

- `transformation::Transformation`: the `Transformation` associated with the plane.
- `material::Material`: the [`Material`](@ref) of the spere.

See also: [`ray_intersection(::Ray, ::Plane)`](@ref)
"""
Base.@kwdef struct Plane <: Shape
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

"""
    ray_intersection(ray::Ray, s::Plane)

Return an [`HitRecord`](@ref) of the nearest ray intersection with the given [`Plane`](@ref).

If none exists, return `nothing`.
"""
function ray_intersection(ray::Ray, s::Plane)
    inv_ray = inv(s.transformation) * ray
    abs(inv_ray.dir.z) < 1f-5 && return nothing
    t = -inv_ray.origin.v[3] / inv_ray.dir.z
    inv_ray.tmin < t < inv_ray.tmax || return nothing
    hit_point = inv_ray(t)
    world_point = s.transformation * hit_point
    normal = -sign(inv_ray.dir.z) * NORMAL_Z
    surface_point = hit_point.v[1:2] - floor.(hit_point.v[1:2]) |> Vec2D
    HitRecord(world_point, normal, surface_point, t, ray, s.material)
end

"""
    quick_ray_intersection(ray::Ray, s::Plane)

Tells if a [`Ray`](@ref) intersect a [`Plane`](@ref) or not.
"""
function quick_ray_intersection(ray::Ray, s::Plane)
    inv_ray = inv(s.transformation) * ray
    inv_ray.dir.z < 1f-5 && return false
    inv_ray.tmin < (-inv_ray.origin.v[3] / inv_ray.dir.z) < inv_ray.tmax
end


#######
# AABB


"""
    AABB

A type representing an Axis-Aligned Bounding Box
"""
Base.@kwdef struct AABB
    p_M::Point = Point(1f0, 1f0, 1f0)
    p_m::Point = Point(0f0, 0f0, 0f0)
end

"""
    ray_intersection(ray::Ray, aabb::AABB)

Return the parameter `t` at which [`Ray`](@ref) first hits the [`AABB`](@ref). If no hit exists, return `Inf32`.
"""
function ray_intersection(ray::Ray, aabb::AABB)
    dir = ray.dir
    overlap = reduce(intersect, map(t -> Interval(t...), zip(-aabb.p_m.v ./ dir, -aabb.p_M.v ./ dir)))
    isempty(overlap) && return Inf32
    t = overlap.first
end
