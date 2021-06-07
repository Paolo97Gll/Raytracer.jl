# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Renderer implementations
# TODO write docstrings


abstract type Renderer <: Function end


################
# OnOffRenderer


struct OnOffRenderer <: Renderer 
    world::World
    on_color::RGB{Float32}
    off_color::RGB{Float32}
end

OnOffRenderer(world::World; on_color::RGB{Float32} = WHITE, off_color::RGB{Float32} = BLACK) = OnOffRenderer(world, on_color, off_color)

function (oor::OnOffRenderer)(ray::Ray)
    isnothing(ray_intersection(ray, oor.world)) ? oor.off_color : oor.on_color
end


###############
# FlatRenderer


struct FlatRenderer <: Renderer
    world::World
    background_color::RGB{Float32}
end

FlatRenderer(world::World; background_color::RGB{Float32} = BLACK) = FlatRenderer(world, background_color)

function (fr::FlatRenderer)(ray::Ray)
    hit = ray_intersection(ray, fr.world)
    isnothing(hit) ? fr.background_color : hit.material.emitted_radiance(hit.surface_point) + hit.material.brdf.pigment(hit.surface_point)
end


#############
# PathTracer


struct PathTracer <: Renderer
    world::World
    background_color::RGB{Float32}
    rng::PCG
    n::Int
    max_depth::Int
    roulette_depth::Int
end

function PathTracer(world::World; background_color::RGB{Float32} = BLACK, rng::PCG = PCG(), n::Int = 10, max_depth::Int = 2, roulette_depth::Int = 3)
    PathTracer(world, background_color, rng, n, max_depth, roulette_depth)
end

function (pt::PathTracer)(ray::Ray)
    ray.depth > pt.max_depth && return BLACK

    hit_record = ray_intersection(ray, pt.world)
    isnothing(hit_record) && return pt.background_color

    hit_material = hit_record.material
    hit_color = hit_material.brdf.pigment(hit_record.surface_point)
    emitted_radiance = hit_material.emitted_radiance(hit_record.surface_point)

    hit_color_lum = max(hit_color...)

    # Russian roulette
    if ray.depth >= pt.roulette_depth
        # q = max(0.05f0, 1f0 - hit_color_lum)
        # if rand(pt.rng, Float32) > q
        #     # Keep the recursion going, but compensate for other potentially discarded rays
        #     hit_color *= 1f0 / (1f0 - q)
        if rand(pt.rng, Float32) > hit_color_lum
            hit_color *= 1f0 / (1f0 - hit_color_lum)
        else
            # Terminate prematurely
            return emitted_radiance
        end
    end

    # Monte Carlo integration
    cum_radiance = BLACK
    # Only do costly recursions if it's worth it
    if hit_color_lum > 0f0
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
    
    emitted_radiance + cum_radiance * (1f0 / pt.n)
end
