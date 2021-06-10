# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Implementation of the abstract type Shape and the derivative concrete types


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
    struct Sphere <: Shape

A type representing a sphere.

This is a unitary sphere centered in the origin. A generic sphere can be specified by applying a [`Transformation`](@ref).

# Members

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
    normal = convert(Normal, point) |> normalize
    (normal ⋅ ray.dir < 0) ? normal : -normal
end

########
# Plane


"""
    struct Plane <: Shape

A type representing an infinite plane.

# Members

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


#######
# AABB


"""
    struct AABB

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
    t = ray_intersection(scaling(2f0) * ray, AABB(Point(fill(1f0, 3)), Point(fill(-1f0, 3))))
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

function get_normal(::Type{Cube}, point::Point, ray::Ray)
    abs_point = point.v .|> abs |> Point
    _, index = findmax(abs_point.v)

    @assert 1 <= index <= 3

    s = -sign(point[index] * ray.dir[index])

    @assert s != 0

    [i == index ? s * 1f0 : 0f0 for i ∈ 1:3] |> Normal{true}
end


Base.@kwdef struct Cylinder <: Shape
    transformation::Transformation = Transformation()
    material::Material = Material()
end

function get_t(::Type{Cylinder}, ray::Ray)
    sray = scaling(2) * ray
    ox, oy, oz = sray.origin.v
    dx, dy, dz = sray.dir

    # check if side is hit
    a = dx^2 + dy^2
    b = 2 * (ox * dx + oy * dy)
    c = ox^2 + oy^2 - 1
    Δ = b^2 - 4f0 * a * c
    Δ < 0 && return nothing
    sqrt_Δ = sqrt(Δ)
    t_1 = (-b - sqrt_Δ) / (2f0 * a)
    t_2 = (-b + sqrt_Δ) / (2f0 * a)
    # nearest point
    if ray.tmin < t_1 < ray.tmax
        t_side = t_1
        abs(oz + t_side * dz) <= 1f0 && return t_side
    elseif ray.tmin < t_2 < ray.tmax
        t_side = t_2
    else
        t_side = Inf32
    end


    # check if caps are hit
    tz1, tz2 = minmax(( 1f0 - oz) / dz, (-1f0 - oz) / dz)
    ispos1, ispos2 = (tz1, tz2) .∈ Ref(Interval(minmax(t_1, t_2)...))
    if ispos1
        @assert ((ox + tz1 * dx)^2 + (oy + tz1 * dy)^2 <= 1)
        return tz1
    elseif ispos2
        @assert ((ox + tz2 * dx)^2 + (oy + tz2 * dy)^2 <= 1)
        return tz2
    else
        return nothing
    end
end

function get_normal(::Type{Cylinder}, point::Point, ray::Ray)
    z = point.v[3]
    # if it comes from the caps
    (abs(z) ≈ 1f0) && return -sign(z) * sign(ray.dir.z) * NORMAL_Z

    # if it comes from the side
    x, y = normalize(point.v[1:2])
    normal = Normal{true}(x, y, 0f0)
    (normal ⋅ ray.dir < 0) ? normal : -normal
end

function get_uv(::Type{Cylinder}, point::Point)
    z = point.v[3]
    x, y = normalize(point.v[1:2])
    z ≈  0.5f0 && return Vec2D(3 - x, 3 - y) * 0.25f0
    z ≈ -0.5f0 && return Vec2D(3 - x, 1 + y) * 0.25f0
    (clamp(z + 0.5f0, 0, 1), (atan(y, x)/2π + 1) * 0.5f0)
end
    