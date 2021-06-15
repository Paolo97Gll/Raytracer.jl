# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Point light sources used by point-light tracer


@doc raw"""
    PointLight

A point light (used by [`PointLightRenderer`](@ref)).

This type holds information about a point light.

# Members

- `position::Point`: a [`Point`](@ref) object holding the position of the point light in 3D space.
- `color::RGB{Float32}`: the color of the point light.
- `linear_radius::Float32`: radius of the source, used to compute solid angle subtended by the light.

If `linear_radius` is non-zero, it is used to compute the solid angle subtended by the light at a given
distance `d` through the formula:

```math
\left(\frac{\mathrm{linear\_radius}}{d}\right)^2
```
"""
Base.@kwdef struct PointLight
    position::Point = ORIGIN
    color::RGB{Float32} = WHITE
    linear_radius::Float32 = 0f0
end

@doc """
    PointLight(position::Point, color::RGB{Float32}, linear_radius::Float32)

Constructor for a [`PointLight`](@ref) instance.
""" PointLight(::Point, ::RGB{Float32}, ::Float32)

@doc """
    PointLight(; position::Point = ORIGIN,
                 color::RGB{Float32} = WHITE,
                 linear_radius::Float32 = 0f0)

Constructor for a [`PointLight`](@ref) instance.

If no parameter is specified, it return a white point light in the origin with no radius.
""" PointLight(; ::Point, ::RGB{Float32}, ::Float32)


"""
    Lights

Alias of `Vector{PointLight}`, to store a list of [`PointLight`](@ref) sources.
"""
const Lights = Vector{PointLight}
