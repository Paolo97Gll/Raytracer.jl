# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

#######
# AABB


"""
    struct AABB

A type representing an Axis-Aligned Bounding Box.
"""
Base.@kwdef struct AABB
    p_M::Point = Point(1f0, 1f0, 1f0)
    p_m::Point = Point(0f0, 0f0, 0f0)
end

"""
    get_t(ray::Ray, aabb::AABB)

Return the parameter `t` at which [`Ray`](@ref) first hits the [`AABB`](@ref). If no hit exists, return `Inf32`.
"""
function get_t(ray::Ray, aabb::AABB)
    dir = ray.dir
    o = ray.origin
    overlap = reduce(intersect, map(t -> Interval(extrema(t)...), zip((aabb.p_m - o) ./ dir, (aabb.p_M - o) ./ dir)))
    isempty(overlap) && return Inf32
    t1, t2 = overlap.first, overlap.last
    ray.tmin < t1 < ray.tmax && return t1
    ray.tmin < t2 < ray.tmax && return t2
    return Inf32
end

function get_all_ts(ray::Ray, aabb::AABB)
    dir = ray.dir
    o = ray.origin
    overlap = reduce(intersect, map(t -> Interval(extrema(t)...), zip((aabb.p_m - o) ./ dir, (aabb.p_M - o) ./ dir)))
    isempty(overlap) && return Vector{Float32}()
    t1, t2 = overlap.first, overlap.last
    isfinite(t1) && (@assert isfinite(t2); return [t1, t2])
    @assert !isfinite(t2)
    return Vector{Float32}()
end
