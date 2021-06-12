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

@doc """
    ray_intersection(ray, s)

Return an [`HitRecord`](@ref) of the nearest ray intersection with the given [`Shape`](@ref),
if none exists, return `nothing`.
""" ray_intersection(::Ray, ::Shape)

function ray_intersection(ray::Ray, s::S) where {S <: Shape}
    inv_ray = inv(s.transformation) * ray
    t = get_t(S, inv_ray)
    isfinite(t) || return nothing
    hit_point = inv_ray(t)
    world_point = s.transformation * hit_point
    normal = s.transformation * get_normal(S, hit_point, inv_ray) 
    surface_point = get_uv(S, hit_point)
    HitRecord(world_point, normal, surface_point, t, ray, s.material)
end

@doc """
    all_ray_intersections(ray, s)

Return a `Vector` of [`HitRecord`](@ref)s of all the ray intersections with the given [`Shape`](@ref) for every finite value of `t`, even outside of the ray domain.
""" all_ray_intersections(::Ray, ::Shape)

function all_ray_intersections(ray::Ray, s::S) where {S <: Shape}
    inv_ray = inv(s.transformation) * ray
    inv_ray = Ray(inv_ray.origin, inv_ray.dir, -Inf32, Inf32, 0)
    ts = get_all_ts(S, inv_ray)
    isempty(ts) && return Vector{HitRecord}()
    hit_points = inv_ray.(ts)
    world_points = Ref(s.transformation) .* hit_points
    normals = Ref(s.transformation) .* get_normal.(S, hit_points, Ref(inv_ray)) 
    surface_points = get_uv.(S, hit_points)
    HitRecord.(world_points, normals, surface_points, ts, Ref(ray), Ref(s.material))
end

@doc """
    quick_ray_intersection(ray, s)

Return whether the ray intersects the given [`Shape`](@ref).
""" quick_ray_intersection(::Ray, ::Shape)

function quick_ray_intersection(ray::Ray, s::S) where {S <: Shape}
    inv_ray = inv(s.transformation) * ray
    isfinite(get_t(S, inv_ray))
end

"""
    SimpleShape <: Shape

Abstract type representing shapes that can be represented as transformed unitary shapes.

An example of simple shape is the parallelepiped: every instance of this shape can be transformed back into a cube of unitary size. 
Therefore, these shapes are univocally determined by their type (e.g. a cuboid) and the transformation that morphs the unitary shape in the desired shape.

See also: [`Shape`](@ref), [`Transformation`](@ref)
"""
abstract type SimpleShape <: Shape end

@doc """
    get_t(::Type{<:SimpleShape}, ray::Ray)

Return the parameter `t` at which [`Ray`](@ref) first hits the unitary [`SimpleShape`](@ref). If no hit exists, return `Inf32`.
""" get_t(::Type{<:Shape}, ::Ray)

"""
    CompositeShape <: Shape

Abstract type representing shapes composed of other shapes.

These shapes cannot be easily described as transformed versions of a unitary shape, and so they differ from [`SimpleShapes`](@ref) under many aspects.

See also: [`Shape`](@ref), [`Transformation`](@ref)
"""
abstract type CompositeShape <: Shape end

let shapesdir = "shapes"
    # Bounding boxes
    include(joinpath(shapesdir, "aabb.jl"))

    # Simple shapes
    include(joinpath(shapesdir, "cube.jl"))
    include(joinpath(shapesdir, "cylinder.jl"))
    include(joinpath(shapesdir, "plane.jl"))
    include(joinpath(shapesdir, "sphere.jl"))

    # Composite shapes
    include(joinpath(shapesdir, "csg.jl"))
end