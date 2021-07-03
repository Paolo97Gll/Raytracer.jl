# [Extendability](@id extendability)

## Contents

```@contents
Pages = ["extendability.md"]
```

## Description

Raytracer is designed to be easily extensible in terms of renderers, pigments, BRDFs, and shapes. To extend the package, one must follow the following guidelines.

## Renderers

##### Needed fields

No fields are strictly needed, but it is suggested to have a [`World`](@ref) field, named `world` for code consistency, in which to store the shapes to be rendered. It is also common to store a background color that deals with rays which do not hit any shape.

##### Needed methods

Each subtype of [`Renderer`](@ref) must be a callable like `(r::Renderer)(ray::Ray)` and must return a `RGB{Float32}`.

##### Further notes

See doc and source code for [`Renderer`](@ref).

## Pigments

##### Needed fields

No fields are needed.

##### Needed methods

Each subtype of [`Pigment`](@ref) must be a callable like `(p::Pigment)(uv::Vec2D)` and must return a `RGB{Float32}`.

##### Further notes

See doc and souce code for [`Pigment`](@ref).

## BRDFs

##### Needed fields

- `pigment::Pigment`: a [`Pigment`](@ref) storing the pigment on which the BRDF operates. It is suggested that this field should have a default value (most BRDFs use the default [`UniformPigment`](@ref)).

##### Needed methods

Each subtype of [`BRDF`](@ref) must implement an `at(::NewBRDF, ::Normal, in_dir::Vec, out_dir::Vec, uv::Vec2D)` function, where `NewBRDF` should be swubstituted with your new type name. This function evaluates the BRDF of a point with given normal, input and output directions and uv coordinates (which are used to evaluate).

##### Further notes

See doc and souce code for [`BRDF`](@ref).

## Shapes

##### Needed fields

- `material::Material`: a [`Material`](@ref) storing the informations on the material of the shape.
- `transformation::Transformation`: a [`Transformation`](@ref) is the transformation that should be applied to every point of the unitary shape associated with the type (e.g., a sphere of radius one for the [`Sphere`](@ref) shape) to be transformed in the desired shape.

##### Needed methods

- `ray_intersection(::Ray, ::NewShape)`: return an [`HitRecord`](@ref) of the nearest ray intersection with the given [`Shape`](@ref).
- `all_ray_intersections(::Ray, ::NewShape)`: return a `Vector` of [`HitRecord`](@ref)s of all the ray intersections with the given [`Shape`](@ref) for every finite value of `t`, even outside of the ray domain.
- `quick_ray_intersection(::Ray, ::NewShape)`: return whether the ray intersects the given [`Shape`](@ref).
- `get_all_ts(::NewShape, ::Ray)`: return a `Vector` of the hit parameter `t` against the given [`Shape`](@ref), even outside of the ray domain.

Furthermore, if you want to make your `NewShape` a subtype of [`SimpleShape`](@ref) you should also implement the following methods:

- `get_t(::Type{NewShape}, ::Ray)`: return the parameter `t` at which [`Ray`](@ref) first hits the unitary [`SimpleShape`](@ref). If no hit exists, return `Inf32`.
- `get_all_ts(::Type{NewShape}, ::Ray)`: return a `Vector` of the hit parameter `t` against the unitary shape of the given [`SimpleShape`](@ref) type, even outside of the ray domain.
- `get_normal(::Type{NewShape}, ::Point, ::Ray)`: return the [`Normal{true}`](@ref) of a shape given a point on its surface and the ray that hits it.
- `get_uv(::Type{NewShape}, ::Point)`: return the uv coordinates of a shape associated with the given point on its surface.

##### Further notes

We suggest to implement any new composite shape as a subtype to [`CompositeShape`](@ref) instead of directly subtyping [`Shape`](@ref).

See documentation and source code of [`Shape`](@ref), [`SimpleShape`](@ref), and [`CompositeShape`](@ref).

## Examples of extendability

Take a look to the examples folder in the repository to see an example (see `examples\extendability\renderers`), also reported below here.

```julia
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
```

Which outputs the following image:

![](https://i.imgur.com/T3UmNOO.jpg)

As you can see, to extend the package one only needs to implement the required subtypes and methods. This is called "type piracy" and is a powerful feature of Julia.

We provided the basic instructions for rendering use, but made so that it is easy for anyone knowing the basics of Julia to build upon these fundations according to their needs.

Detailed instructions on how to implement new simple and composite shapes are also written in the `src/shapes.jl` file.
