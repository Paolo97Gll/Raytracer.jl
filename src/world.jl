# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# World containing a collection of shapes


"""
    World

Alias of `Vector{Shape}`, to store a list of [`Shape`](@ref).
"""
const World = Vector{Shape}

"""
    ray_intersection(ray::Ray, world::World)

Intersect a [`Ray`](@ref) with each [`Shape`](@ref) in [`World`](@ref) and return the nearest hit point.
"""
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

"""
    is_point_visible(world::World, point::Point, observer_pos::Point)

Tells if a particular [`Point`](@ref) in a [`World`](@ref) filled with [`Shape`](@ref) is visible from the observer position.
"""
function is_point_visible(world::World, point::Point, observer_pos::Point)
    direction = point - observer_pos
    dir_norm = norm(direction)

    ray = Ray(observer_pos, direction, 1f-2 / dir_norm, 1f0, 0)

    return !any(shape -> quick_ray_intersection(ray, shape), world)
end
