# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Renderer implementations
# TODO write docstrings


abstract type Renderer <: Function end


################
# OnOffRenderer


Base.@kwdef struct OnOffRenderer <: Renderer 
    world::World
    on_color::RGB{Float32} = WHITE
    off_color::RGB{Float32} = BLACK
end

function (oor::OnOffRenderer)(ray::Ray)
    ray_intersection(ray, oor.world) !== nothing ? oor.on_color : oor.off_color
end


###############
# FlatRenderer


Base.@kwdef struct FlatRenderer <: Renderer 
    world::World
    background_color::RGB{Float32} = BLACK
end

function (fr::FlatRenderer)(ray::Ray)
    (hit = ray_intersection(ray, fr.world)) !== nothing ? hit.material.emitted_radiance(hit.surface_point) + hit.material.brdf.pigment(hit.surface_point) : fr.background_color
end


#############
# PathTracer


Base.@kwdef struct PathTracer <: Renderer
    world::World
    background_color::RGB{Float32} = BLACK
    rng::PCG
    n::Int
    max_depth::Int
    roulette_depth::Int
end

function (pt::PathTracer)(ray::Ray)
    ray.depth > pt.max_depth && return BLACK

    hit_record = ray_intersection(ray, pt.world)
    isnothing(hit_record) && return pt.background_color

    hit_material = hit_record.material
    hit_color = hit_material.brdf.pigment(hit_record.surface_point) |> RGB{Float32}
    emitted_radiance = hit_material.emitted_radiance(hit_record.surface_point)

    hit_color_lum = max(hit_color...)

    # Russian roulette
    if ray.depth >= pt.roulette_depth
        q = max(0.05f0, 1f0 - hit_color_lum)
        if rand(pt.rng, Float32) > q
            # Keep the recursion going, but compensate for other potentially discarded rays
            hit_color *= (1f0/(1f0 - q))
        else
            # Terminate prematurely
            return emitted_radiance
        end
    end

    # Monte Carlo integration
    
    cum_radiance = BLACK
    
    # Only do costly recursions if it's worth it
    if hit_color_lum > 0
        for _ ∈ 1:pt.n
            new_ray = scatter_ray(
                hit_material.brdf,
                pt.rng,
                hit_record.ray.dir,
                hit_record.world_point,
                hit_record.normal,
                ray.depth + 1
            )
            # Recursive call
            new_radiance = pt(new_ray)
            cum_radiance += hit_color * new_radiance
        end
    end
    
    emitted_radiance + cum_radiance * (1 / pt.n)
end
