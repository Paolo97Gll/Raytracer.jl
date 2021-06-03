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
    HitRecord

A struct representing the result of an intersection between
a [`Ray`](@ref) and a [`Shape`](@ref).
"""
struct HitRecord{T}
    world_point::Point{T}
    normal::Normal{T}
    surface_point::Vec2D{T}
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

################################################################


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

function ray_intersection(ray::Ray{T}, s::Sphere) where {T}
    inv_ray = inv(s.transformation) * ray
    # compute intersection
    origin_vec = convert(Vec, inv_ray.origin)
    a = norm²(inv_ray.dir)
    b = 2f0 * origin_vec ⋅ inv_ray.dir
    c = norm²(origin_vec) - 1f0
    Δ = b^2 - 4 * a * c
    Δ < 0 && return nothing
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
    u = u >= 0 ? u : u+1f0
    v = acos(hit_point[3]) / π
    surface_point = Vec2D{T}(u, v)
    HitRecord{T}(world_point, normal, surface_point, hit_t, ray, s.material)
end

"""
    Plane <: Shape

A type representing an infinite plane.
"""
Base.@kwdef struct Plane <: Shape
    transformation::Transformation = Transformation{Bool}()
    material::Material = Material()
end

function ray_intersection(ray::Ray{T}, s::Plane) where {T}
    inv_ray = inv(s.transformation) * ray
    dz = inv_ray.dir.z
    t = -inv_ray.origin.v[3]/dz
    inv_ray.tmin < t < inv_ray.tmax || return nothing
    hit_point = inv_ray(t)
    world_point = s.transformation * hit_point
    normal = -sign(dz) * normal_z(T)
    surface_point = hit_point.v[1:2] - floor.(hit_point.v[1:2]) |> Vec2D{T}
    HitRecord{T}(world_point, normal, surface_point, t, ray, s.material)
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
function ray_intersection(ray::Ray{T}, aabb::AABB) where T
    dir = ray.dir
    overlap = reduce(intersect, map(t -> Interval(t...), zip(-aabb.p_m.v ./ dir, -aabb.p_M.v ./ dir))) 
    isempty(overlap) && return typemax(T)
    t = overlap.first
end
