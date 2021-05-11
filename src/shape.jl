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
        print(io, "  ", rpad(fieldname, n), " = ", getfield(s, fieldname))
    end
end

"""
    HitRecord

A struct representing the result of an intersection between
a [`Ray`](@ref) and a [`Shape`](@ref).
"""
struct HitRecord
    world_point::Point
    normal::Normal
    surface_point::Vec2D
    t::Real
    ray::Ray
end

function show(io::IO, ::MIME"text/plain", hr::T) where {T <: HitRecord}
    print(io, T)
    fns = fieldnames(T)
    n = maximum(fns .|> String .|> length)
    for fieldname ∈ fns
        println(io)
        print(io, "  ", rpad(fieldname, n), " = ", getfield(hr, fieldname))
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

#####################################################################


"""
    Sphere

An abstract type representing a shape.
"""
Base.@kwdef struct Sphere <: Shape
    transformation::Transformation = Transformation{Bool}()
end

@doc """
    ray_intersection(ray, s)

Return an [`HitRecord`](@ref) of the nearest ray intersection with the given [`Shape`](@ref),
if none exists, return `nothing`.
""" ray_intersection

function ray_intersection(ray::Ray, s::Sphere)
    inv_ray = inverse(s.transformation) * ray
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
    surface_point = Vec2D{eltype(ray)}(atan(hit_point.v[2]/hit_point.v[1])/2π, acos(hit_point.v[3])/π)
    HitRecord(world_point, normal, surface_point, hit_t, ray)
end