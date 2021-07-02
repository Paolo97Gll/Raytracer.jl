using Pkg; Pkg.activate(joinpath("..", "..", ".."))

using Raytracer
using Raytracer.Interpreter

"""
    FoggyRenderer <: Renderer

A `Renderer` that returns the color of the `Shape` first hit by a given `Ray` mixed with the fog_color depending on distance travelled.

This renderer returns the color stored in the `material` field of the `Shape` first hit by the given `Ray` at the hit point.
To this renderer there is no difference between radiated light and reflected color. There are no shades, diffusions or reflections.
The color is then mixed with the `fog color` using the formula
``(1-\\exp{-t/λ}) fog_color + \\exp{-t/λ} hit_color``
where `t` is the distance to the hit point and `λ` is the luminosity falloff.
If there are no hits this renderer returns the value of its field `fog_color`.

# Fields

- `world::World`: the `World` to render.
- `fog_color::RGB{Float32}`: color of the fog.
- `falloff::Float32`: color falloff
"""
struct FoggyRenderer <: Renderer
	world::World
	fog_color::RGB{Float32}
	falloff::Float32
end

@doc """
    FoggyRenderer(world::World, fog_color::RGB{Float32}, falloff::Float32)

Constructor for a `FoggyRenderer` instance.
""" FoggyRenderer(::World, ::RGB{Float32}, ::Float32)

"""
    FoggyRenderer(world::World; fog_color::RGB{Float32} = BLACK, falloff::Float32 = 1f0)

Constructor for a `FoggyRenderer` instance.

If no color is specified, it will default on [`BLACK`](@ref).
"""
FoggyRenderer(world::World; fog_color::RGB{Float32} = BLACK, falloff::Float32 = 1f0) = FlatRenderer(world, fog_color, falloff)

"""
    (oor::FoggyRenderer)(ray::Ray)

Render a `Ray` and return a `RBG{Float32}`.
"""
function (fr::FoggyRenderer)(ray::Ray)
    hit = ray_intersection(ray, fr.world)
    isnothing(hit) && return fr.fog_color 
	hit_color = hit.material.emitted_radiance(hit.surface_point) + hit.material.brdf.pigment(hit.surface_point)
	t = hit.t/fr.falloff
	fr.fog_color * (1 - exp(-t)) + hit_color * exp(-t)
end

scene = open_stream(parse_scene, "test_scene.sl")

image_tracer = ImageTracer(scene.image, scene.camera; scene.tracer.kwargs...)
renderer = FoggyRenderer(scene.world, WHITE, 10f0)
render(image_tracer, renderer, output_file="foggy_renderer_out.pfm")
tonemapping("foggy_renderer_out.pfm", "foggy_renderer_out.jpg", luminosity = 0.5f0)