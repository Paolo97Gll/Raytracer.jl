# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# World containing a collection of shapes
# TODO write docstrings

"""
    PointLight

A point light (used by the point-light renderer)

This type holds information about a point light. 

# Fields

-   `position`: a `Point` object holding the position of the point light in 3D space
-   `color`: the color of the point light (an instance of `RGB{Float32}`)
-   `linear_radius`: a `Float32` number. If non-zero, this «linear radius» `r` is used to compute the solid
    angle subtended by the light at a given distance `d` through the formula `(r / d)²`.

------------------------------------------------------------------------------------------

    PointLight(; position::Point = ORIGIN, 
                 color::RGB{Float32} = WHITE, 
                 linear_radius::Float32 = 0f0)

Constructor for a [`PointLight`](@ref) instance.

"""
Base.@kwdef struct PointLight
    position::Point = ORIGIN
    color::RGB{Float32} = WHITE
    linear_radius::Float32 = 0f0
end

const Lights = Vector{PointLight}
