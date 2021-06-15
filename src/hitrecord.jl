# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# HitRecord for store the result of an intersection between a Ray and a Shape


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
