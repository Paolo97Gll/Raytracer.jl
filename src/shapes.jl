# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Implementation of the abstract type Shape and the derivative concrete types,
# such as Sphere or Plane
# TODO write docstrings


################################################################


"""
    HitRecord

A struct representing the result of an intersection between a [`Ray`](@ref) and a [`Shape`](@ref).

# Members

- `world_point::Point`: a [`Point`](@ref) representing the world coordinates of the hit point.
- `normal::Normal`: a [`Normal`](@ref) representing the orientation of the normal to the surface where the hit happened.
- `surface_point::Vec2D`: a [`Vec2D`](@ref) representing the position of the hit point on the surface of the object.
- `t::Float32`: distance from the origin of the ray where the hit happened.
- `ray::Ray`: a [`Ray`](@ref) representing the the ray that hit the surface.
- `material::Material`: a [`Material`](@ref) representing the material of the point where the hit happened.
"""
struct HitRecord
    world_point::Point
    normal::Normal
    surface_point::Vec2D
    t::Float32
    ray::Ray
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

"""
    ≈(hr1::HitRecord, hr2::HitRecord)

Check if two [`HitRecord`](@ref) represent the same hit event or not.
"""
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

"""
    ray_intersection(ray, s)

Return an [`HitRecord`](@ref) of the nearest ray intersection with the given [`Shape`](@ref),
if none exists, return `nothing`.
"""
function ray_intersection(ray::Ray, s::S) where {S <: Shape}
    inv_ray = inv(s.transformation) * ray
    t = get_t(S, inv_ray)
    isnothing(t) && return nothing
    hit_point = inv_ray(t)
    world_point = s.transformation * hit_point
    normal = s.transformation * get_normal(S, hit_point, inv_ray) 
    surface_point = get_uv(S, hit_point)
    HitRecord(world_point, normal, surface_point, t, ray, s.material)
end

"""
    quick_ray_intersection(ray, s)

Return whether the ray intersects the given [`Shape`](@ref).
"""
function quick_ray_intersection(ray::Ray, s::S) where {S <: Shape}
    inv_ray = inv(s.transformation) * ray
    !isnothing(get_t(S, inv_ray))
end

#########
# Sphere


"""
    Sphere <: Shape

A type representing a sphere.

# Members

- `transformation::Transformation`
"""
Base.@kwdef struct Sphere <: Shape
    transformation::Transformation = Transformation()
    material::Material = Material()
end

function get_t(::Type{Sphere}, ray::Ray)
    # compute intersection
    origin_vec = convert(Vec, ray.origin)
    a = norm²(ray.dir)
    b = 2f0 * origin_vec ⋅ ray.dir
    c = norm²(origin_vec) - 1f0
    Δ = b^2 - 4f0 * a * c
    Δ < 0 && return nothing
    sqrt_Δ = sqrt(Δ)
    t_1 = (-b - sqrt_Δ) / (2f0 * a)
    t_2 = (-b + sqrt_Δ) / (2f0 * a)
    # nearest point
    if (t_1 > ray.tmin) && (t_1 < ray.tmax)
        return t_1
    elseif (t_2 > ray.tmin) && (t_2 < ray.tmax)
        return t_2
    else
        return nothing
    end
end

function get_uv(::Type{Sphere}, point::Point)
    u = atan(point[2], point[1]) / (2f0 * π)
    u = u >= 0 ? u : u+1f0
    v = acos(clamp(point[3], -1f0, 1f0)) / π
    Vec2D(u, v)
end

function get_normal(::Type{Sphere}, point::Point, ray::Ray)
    normal = convert(Normal, point)
    (normal ⋅ ray.dir < 0) ? normal : -normal
end

# function quick_ray_intersection(ray::Ray, s::Sphere)
#     inv_ray = inv(s.transformation) * ray
#     origin_vec = convert(Vec, inv_ray.origin)
#     a = norm²(inv_ray.dir)
#     b = 2f0 * origin_vec ⋅ inv_ray.dir
#     c = norm²(origin_vec) - 1f0
#     Δ = b^2 - 4f0 * a * c
#     Δ < 0f0 && return false
#     sqrt_Δ = sqrt(Δ)
#     (inv_ray.tmin < (-b-sqrt_Δ)/(2f0*a) < inv_ray.tmax) || (inv_ray.tmin < (-b+sqrt_Δ)/(2f0*a) < inv_ray.tmax)
# end


########
# Plane


"""
    Plane <: Shape

A type representing an infinite plane.
"""
Base.@kwdef struct Plane <: Shape
    transformation::Transformation = Transformation()
    material::Material = Material()
end

function get_t(::Type{Plane}, ray::Ray)
    abs(ray.dir.z) < 1f-5 && return nothing
    t = -ray.origin.v[3] / ray.dir.z
    ray.tmin < t < ray.tmax ? t : nothing
end

function get_uv(::Type{Plane}, point::Point)
    point.v[1:2] - floor.(point.v[1:2]) |> Vec2D
end

function get_normal(::Type{Plane}, point::Point, ray::Ray)
    -sign(ray.dir.z) * NORMAL_Z
end

# function quick_ray_intersection(ray::Ray, s::Plane)
#     inv_ray = inv(s.transformation) * ray
#     inv_ray.dir.z < 1f-5 && return false
#     inv_ray.tmin < (-inv_ray.origin.v[3] / inv_ray.dir.z) < inv_ray.tmax
# end


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
    ray_intersection(ray, aabb)

Return the parameter `t` at which `ray` first hits the bounding box. If no hit exists, return `Inf32`.
"""
function ray_intersection(ray::Ray, aabb::AABB)
    dir = ray.dir
    o = ray.origin
    overlap = reduce(intersect, map(t -> Interval(extrema(t)...), zip((aabb.p_m - o) ./ dir, (aabb.p_M - o) ./ dir)))
    isempty(overlap) && return Inf32 
    t1, t2 = overlap.first, overlap.last
    ray.tmin < t1 < ray.tmax && return t1
    ray.tmin < t2 < ray.tmax && return t2
end

#######
# Cube

Base.@kwdef struct Cube <: Shape
    transformation::Transformation = Transformation()
    material::Material = Material()
end

function get_t(::Type{Cube}, ray::Ray)
    t = ray_intersection(ray, AABB(Point(fill(5f-1, 3)), Point(fill(-5f-1, 3))))
    ray.tmin < t < ray.tmax ? t : nothing
end

function get_uv(::Type{Cube}, point::Point)
    x, y, z = point
    abs_point = point.v .|> abs |> Point
    maxval, index = findmax(abs_point.v)

    @assert 1 <= index <= 3

    ispos = point[index] > 0

    if index == 1 
        uc = ispos ? z : -z
        vc = y
        offset = (ispos ? 2 : 0, 1)  
    elseif index == 2
        uc = x;
        vc = ispos ? z : -z
        offset = (1, ispos ? 2 : 0)
    else 
        uc = ispos ? -x : x
        vc = y
        offset = (ispos ? 3 : 1, 1)
    end

    @.((offset + 0.5f0 * ((uc, vc) / maxval + 1f0))/(4f0, 3f0)) |> Vec2D
end

# UNUSED, STORED HERE IF NEDDED IN FUTURE
# function get_xyz(::Type{Cube}, uv::Vec2D)
#     ucvc = uv .* (4f0, 3f0)
#     offset = ucvc .|> floor .|> Int |> Tuple
#     uc, vc = (ucvc - offset) * 2 - 1f0
#     offset == (2, 1) && return Vec( 1f0,   vc,  -uc) # positive x
#     offset == (0, 1) && return Vec(-1f0,   vc,   uc) # negative x
#     offset == (1, 2) && return Vec(  uc,  1f0,  -vc) # positive y
#     offset == (1, 0) && return Vec(  uc, -1f0,   vc) # negative y
#     offset == (1, 1) && return Vec(  uc,   vc,  1f0) # positive z
#     offset == (3, 1) && return Vec( -uc,   vc, -1f0) # negative z
#     error("Invalid uv coordinate for a Cube: got $uv")
# end

function get_normal(::Type{Cube}, point::Point, ray::Ray)
    abs_point = point.v .|> abs |> Point
    _, index = findmax(abs_point.v)

    @assert 1 <= index <= 3

    s = -sign(point[index] * ray.dir[index])

    @assert s != 0

    [i == index ? s * 1f0 : 0f0 for i ∈ 1:3] |> Normal{true}
end

