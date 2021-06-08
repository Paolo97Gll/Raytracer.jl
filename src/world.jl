# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# World containing a collection of shapes
# TODO write docstrings


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

function is_point_visible(world::World, point::Point, observer_pos::Point)
    direction = point - observer_pos
    dir_norm = norm(direction)

    ray = Ray(observer_pos, direction, 1f-2 / dir_norm, 1f0, 0)

    return !any(shape -> quick_ray_intersection(ray, shape), world)
end