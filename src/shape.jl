# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   shape.jl
# description:
#   Implementation of the abstract type Shape and the derivative
#   concrete types, such as Sphere

# TODO check docstrings


"""
    Shape

An abstract type representing a shape.
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

"""
    HitRecord

A struct representing the result of an intersection between
a [`Ray`](@ref) and a [`Shape`](@ref).
"""
struct HitRecord{T}
    world_point::Point
    normal::Normal
    surface_point::Vec2D
    t::T
    ray::Ray{T}
    material::Material
end

function show(io::IO, ::MIME"text/plain", hr::T) where {T <: HitRecord}
    print(io, T)
    fns = fieldnames(T)
    n = maximum(fns .|> String .|> length)
    for fieldname ∈ fns
        println(io)
        print(io, " ↳ ", rpad(fieldname, n), " = ", getfield(hr, fieldname))
    end
end

function (≈)(hr1::HitRecord, hr2::HitRecord)
    sp1, sp2 = hr1.surface_point, hr2.surface_point
    hr1.world_point     ≈  hr2.world_point     &&
    hr1.normal          ≈  hr2.normal          &&
    findall(isnan, sp1) == findall(isnan, sp2) &&
    filter(!isnan, sp1) ≈  filter(!isnan, sp2) &&
    hr1.t               ≈  hr2.t               &&
    hr1.ray             ≈  hr2.ray
end

const World = Vector{Shape}

function ray_intersection(ray::Ray, world::World)
    hit = nothing
    for shape ∈ world
        last_hit = ray_intersection(ray, shape)
        last_hit === nothing && continue
        if hit === nothing 
            hit = last_hit
        else
            last_hit.t/norm(last_hit.ray.dir) >= hit.t/norm(hit.ray.dir) && continue
            hit = last_hit
        end
    end
    hit
end

#####################################################################


"""
    Sphere <: Shape

A type representing a sphere.
"""
Base.@kwdef struct Sphere <: Shape
    transformation::Transformation = Transformation{Bool}()
    material::Material = Material()
end

@doc """
    ray_intersection(ray, s)

Return an [`HitRecord`](@ref) of the nearest ray intersection with the given [`Shape`](@ref),
if none exists, return `nothing`.
""" ray_intersection

function ray_intersection(ray::Ray, s::Sphere)
    inv_ray = inv(s.transformation) * ray
    O⃗ = inv_ray.origin - ORIGIN
    scalprod = O⃗ ⋅ inv_ray.dir
    # Δ/4 where Δ is the discriminant of the intersection system solution
    Δ = (scalprod)^2 - norm²(inv_ray.dir) * (norm²(O⃗) - 1)
    Δ < 0 && return nothing
    # intersection ray-sphere
    t_1 = (-scalprod - Δ) / norm²(inv_ray.dir)
    t_2 = (-scalprod + Δ) / norm²(inv_ray.dir)
    # nearest point 
    if t_1 > inv_ray.tmin && t_1 < inv_ray.tmax
        hit_t = t_1
    elseif t_2 > inv_ray.tmin && t_2 < inv_ray.tmax
        hit_t = t_2
    else
        return nothing
    end
    hit_point = inv_ray(hit_t)
    # generate HitRecord
    world_point = s.transformation * hit_point
    normal = Normal(hit_point.v)
    normal = s.transformation * (normal ⋅ ray.dir < 0. ? normal : -normal)
    v = normalize(hit_point.v)
    surface_point = Vec2D{eltype(ray)}(iszero(v[1:2]) ? 0 : atan(v[2], v[1])/2π + 0.5, 0.5 - asin(v[3])/π)
    HitRecord(world_point, normal, surface_point, convert(eltype(ray), hit_t), ray, s.material)
end

"""
    Plane <: Shape

A type representing an infinite plane.
"""
Base.@kwdef struct Plane <: Shape
    transformation::Transformation = Transformation{Bool}()
    material::Material = Material()
end

function ray_intersection(ray::Ray, s::Plane)
    inv_ray = inv(s.transformation) * ray
    dz = inv_ray.dir.z
    t = -inv_ray.origin.v[3]/dz
    inv_ray.tmin < t < inv_ray.tmax || return nothing
    hit_point = inv_ray(t)
    world_point = s.transformation * hit_point
    normal = -sign(dz) * Normal(eltype(ray) .|> (zero, zero, one))
    surface_point = hit_point.v[1:2] - floor.(hit_point.v[1:2]) |> Vec2D
    HitRecord(world_point, normal, surface_point, convert(eltype(ray), t), ray, s.material)
end

"""
    AABB

A type representing an Axis-Aligned Bounding Box
"""
Base.@kwdef struct AABB{T}
    p_M::Point{T} = Point( one(T),  one(T),  one(T)) 
    p_m::Point{T} = Point(zero(T), zero(T), zero(T))
end

"""
    ray_intersection(ray, aabb)

Return the parameter `t` at which `ray` first hits the bounding box. If no hit exists, return `typemax(eltype(ray))`.
"""
function ray_intersection(ray::Ray, aabb::AABB)
    dir = ray.dir
    overlap = reduce(intersect, map(t -> Interval(t...), zip(-aabb.p_m.v ./ dir, -aabb.p_M.v ./ dir))) 
    isempty(overlap) && return typemax(eltype(ray))
    t = overlap.first
end
