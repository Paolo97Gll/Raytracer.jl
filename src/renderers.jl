abstract type Renderer <: Function end

Base.@kwdef struct OnOffRenderer{T <: AbstractFloat} <: Renderer 
    world::World
    on_color::RGB{T} = one(RGB{T})
    off_color::RGB{T} = zero(RGB{T})
end

function (oor::OnOffRenderer)(ray::Ray)
    ray_intersection(ray, oor.world) !== nothing ? oor.on_color : oor.off_color
end

Base.@kwdef struct FlatRenderer{T <: AbstractFloat} <: Renderer 
    world::World
    background_color::RGB{T} = zero(RGB{T})
end

function (fr::FlatRenderer)(ray::Ray)
    (hit = ray_intersection(ray, fr.world)) !== nothing ? hit.material.emitted_radiance(hit.surface_point) + hit.material.brdf.pigment(hit.surface_point) : fr.background_color
end

Base.@kwdef struct PathTracer{T <: AbstractFloat} <: Renderer
    world::World
    background_color::RGB{T} = zero(RGB{T})
    rng::PCG
    n::Int
    max_depth::Int
    roulette_depth::Int
end

function (pt::PathTracer{T})(ray::Ray) where {T}
    ray.depth > pt.max_depth && return zero(RGB{T})

    hit_record = ray_intersection(ray, pt.world)
    isnothing(hit_record) && return pt.background_color

    hit_material = hit_record.material
    hit_color = hit_material.brdf.pigment(hit_record.surface_point) |> RGB{T}
    emitted_radiance = hit_material.emitted_radiance(hit_record.surface_point)

    hit_color_lum = max(hit_color...)

    # Russian roulette
    if ray.depth >= pt.roulette_depth
        q = max(0.05, 1 - hit_color_lum)
        if rand(pt.rng, eltype(ray)) > q
            # Keep the recursion going, but compensate for other potentially discarded rays
            hit_color *= 1/(1 - q)
        else
            # Terminate prematurely
            return emitted_radiance
        end
    end

    # Monte Carlo integration
    
    cum_radiance = zero(RGB{T})
    
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