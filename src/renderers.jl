# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Renderer implementations


"""
    Renderer

Abstract type for functors that map [`Ray`](@ref) to `RGB{Float32}`.

Each subtype of this type must be a callable like `(r::Renderer)(ray::Ray)` and must return a `RGB{Float32}`.
Each subtype of this type sould have a member of type [`World`](@ref) to check for intersections of the given [`Ray`](@ref).

See also: [`OnOffRenderer`](@ref), [`FlatRenderer`](@ref), [`PathTracer`](@ref), [`PointLightRenderer`](@ref)
"""
abstract type Renderer end


################
# OnOffRenderer

"""
    OnOffRenderer <: Renderer

A basic bichrome [`Renderer`](@ref) that checks whether a [`Ray`](@ref) has collided or not.

This renderer returns its field `off_color` when the given `Ray` is `nothing`, else it returns its field `on_color`.

# Members

- `world::World`: the [`World`](@ref) to render.
- `on_color::RGB{Float32}`: color if the ray collide.
- `off_color::RGB{Float32}`: color if the ray do not collide.
"""
struct OnOffRenderer <: Renderer
    world::World
    on_color::RGB{Float32}
    off_color::RGB{Float32}
end

@doc """
    OnOffRenderer(world::World, on_color::RGB{Float32}, off_color::RGB{Float32})

Constructor for a [`OnOffRenderer`](@ref) instance.
""" OnOffRenderer(::World, ::RGB{Float32}, ::RGB{Float32})

"""
    OnOffRenderer(world::World
                  ; on_color::RGB{Float32} = WHITE,
                    off_color::RGB{Float32} = BLACK)

Constructor for a [`OnOffRenderer`](@ref) instance.

If no color is specified, it will default on [`WHITE`](@ref) and [`BLACK`](@ref).
"""
OnOffRenderer(world::World; on_color::RGB{Float32} = WHITE, off_color::RGB{Float32} = BLACK) = OnOffRenderer(world, on_color, off_color)

"""
    (oor::OnOffRenderer)(ray::Ray)

Render a [`Ray`](@ref) and return a `RBG{Float32}`.
"""
function (oor::OnOffRenderer)(ray::Ray)
    isnothing(ray_intersection(ray, oor.world)) ? oor.off_color : oor.on_color
end


###############
# FlatRenderer

"""
    FlatRenderer <: Renderer

A basic [`Renderer`](@ref) that returns the color of the [`Shape`](@ref) first hit by a given [`Ray`](@ref).

This renderer returns the color stored in the `material` field of the [`Shape`](@ref) first hit by the given [`Ray`](@ref) at the hit point.
To this renderer there is no difference between radiated light and reflected color. There are no shades, diffusions or reflections.
If there are no hits this renderer returns the value of its field `background_color`.

# Members

- `world::World`: the [`World`](@ref) to render.
- `background_color::RGB{Float32}`: color if the ray do not collide.
"""
struct FlatRenderer <: Renderer
    world::World
    background_color::RGB{Float32}
end

@doc """
    FlatRenderer(world::World, background_color::RGB{Float32})

Constructor for a [`FlatRenderer`](@ref) instance.
""" FlatRenderer(::World, ::RGB{Float32})

"""
    FlatRenderer(world::World; background_color::RGB{Float32} = BLACK)

Constructor for a [`FlatRenderer`](@ref) instance.

If no color is specified, it will default on [`BLACK`](@ref).
"""
FlatRenderer(world::World; background_color::RGB{Float32} = BLACK) = FlatRenderer(world, background_color)

"""
    (oor::FlatRenderer)(ray::Ray)

Render a [`Ray`](@ref) and return a `RBG{Float32}`.
"""
function (fr::FlatRenderer)(ray::Ray)
    hit = ray_intersection(ray, fr.world)
    isnothing(hit) ? fr.background_color : hit.material.emitted_radiance(hit.surface_point) + hit.material.brdf.pigment(hit.surface_point)
end


#############
# PathTracer

"""
    PathTracer <: Renderer

A path-tracing [`Renderer`](@ref) that considers the optical path of a [`Ray`](@ref) from the observer to a light source.

# Members

- `world::World`: the [`World`](@ref) to render.
- `background_color::RGB{Float32}`: color if the ray do not collide.
- `rng::PCG`: a [`PCG`](@ref) random number generator to appropriately scatter rays.
- `n::Int`: how many scattered rays should be generated for the mc integration.
- `max_depth::Int`: the maximum number of scatters a ray should be subjected to before stopping.
- `roulette_depth::Int`: the depth at which the russian roulette algorithm should start (if > 'max_depth` then it will never start).
"""
struct PathTracer <: Renderer
    world::World
    background_color::RGB{Float32}
    rng::PCG
    n::Int
    max_depth::Int
    roulette_depth::Int
end

@doc """
    PathTracer(world::World, background_color::RGB{Float32}, rng::PCG, n::Int, max_depth::Int, roulette_depth::Int)

Constructor for a [`PathTracer`](@ref) instance.
""" PathTracer(::World, ::RGB{Float32}, ::PCG, ::Int, ::Int, ::Int)

"""
    PathTracer(world::World
               ; background_color::RGB{Float32} = BLACK,
                 rng::PCG = PCG(),
                 n::Int = 10,
                 max_depth::Int = 2,
                 roulette_depth::Int = 3)

Constructor for a [`PathTracer`](@ref) instance.
"""
function PathTracer(world::World; background_color::RGB{Float32} = BLACK, rng::PCG = PCG(), n::Int = 10, max_depth::Int = 2, roulette_depth::Int = 3)
    PathTracer(world, background_color, rng, n, max_depth, roulette_depth)
end

"""
    (oor::PathTracer)(ray::Ray)

Render a [`Ray`](@ref) and return a `RBG{Float32}`.
"""
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


#####################
# PointLightRenderer


"""
    PointLightRenderer <: Renderer

Point-light tracing [`Renderer`](@ref). This renderer is similar to what POV-Ray provides by default.

# Members

- `world::World`: the [`World`](@ref) to render.
- `lights::Lights`: a [`Lights`](@ref) instance that contain a list of lights.
- `background_color::RGB{Float32}`: color if the ray do not collide.
- `ambient_color::RGB{Float32}`: the ambient color of the scene.
"""
struct PointLightRenderer <: Renderer
    world::World
    lights::Lights
    background_color::RGB{Float32}
    ambient_color::RGB{Float32}
end

@doc """
    PointLightRenderer(world::World, lights::Lights, background_color::RGB{Float32}, ambient_color::RGB{Float32})

Constructor for a [`PointLightRenderer`](@ref) instance.
""" PointLightRenderer(::World, ::Lights, ::RGB{Float32}, ::RGB{Float32})

"""
    PointLightRenderer(world::World, lights::Lights
                       ; background_color::RGB{Float32} = BLACK,
                         ambient_color::RGB{Float32} = WHITE * 1f-3)

Constructor for a [`PointLightRenderer`](@ref) instance.
"""
function PointLightRenderer(world::World, lights::Lights; background_color::RGB{Float32} = BLACK, ambient_color::RGB{Float32} = WHITE * 1f-3)
    PointLightRenderer(world, lights, background_color, ambient_color)
end

"""
    (oor::PointLightRenderer)(ray::Ray)

Render a [`Ray`](@ref) and return a `RBG{Float32}`.
"""
function (plr::PointLightRenderer)(ray::Ray)
    hit_record = ray_intersection(ray, plr.world)
    isnothing(hit_record) && return plr.background_color

    hit_material = hit_record.material

    result_color = plr.ambient_color
    for cur_light ∈ plr.lights
        is_point_visible(plr.world, cur_light.position, hit_record.world_point) || continue

        distance_vec = hit_record.world_point - cur_light.position
        distance = norm(distance_vec)
        in_dir = distance_vec * (1f0 / distance)
        cos_theta = max(0f0, normalized_dot(-ray.dir, hit_record.normal))

        distance_factor = cur_light.linear_radius > 0 ? (cur_light.linear_radius / distance)^2 : 1f0

        emitted_color = hit_material.emitted_radiance(hit_record.surface_point)
        brdf_color = at(hit_material.brdf, hit_record.normal, in_dir, -ray.dir, hit_record.surface_point)

        result_color += (emitted_color + brdf_color) * cur_light.color * cos_theta * distance_factor
    end

    return result_color
end
