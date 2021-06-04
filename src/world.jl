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
