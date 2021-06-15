# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Implementation of the Camera abstract type and the derivating concrete types


###############
# Camera types


"""
    Camera

An abstract type representing an observer.

See also: [`OrthogonalCamera`](@ref), [`PerspectiveCamera`](@ref)
"""
abstract type Camera end


"""
    OrthogonalCamera <: Camera

A [`Camera`](@ref) implementing an orthogonal 3D → 2D projection.

# Members

- `aspect_ratio::Float32`: defines how larger than the height is the image (16/9, 4/3, ...).
- `transformation::Transformation`: define the [`Transformation`](@ref) applied to the rays generated by the camera.

See also: [`fire_ray(::OrthogonalCamera, ::Float32, ::Float32)`](@ref)
"""
Base.@kwdef struct OrthogonalCamera <: Camera
    aspect_ratio::Float32 = 1f0
    transformation::Transformation = Transformation()
end

@doc """
    OrthogonalCamera(aspect_ratio::Float32, transformation::Transformation)

Constructor for an [`OrthogonalCamera`](@ref) instance.
""" OrthogonalCamera(::Float32, ::Transformation)

@doc """
    OrthogonalCamera(; aspect_ratio::Float32 = 1f0,
                       transformation::Transformation = Transformation())

Keyword-based constructor for an [`OrthogonalCamera`](@ref) instance.

If no parameter is specified, it return a camera with square aspect ratio and an identity transformation.
""" OrthogonalCamera(; ::Float32, ::Transformation)


"""
    PerspectiveCamera <: Camera

A [`Camera`](@ref) implementing a perspective 3D → 2D projection.

# Members

- `aspect_ratio::Float32`: defines how larger than the height is the image (16/9, 4/3, ...).
- `transformation::Transformation`: define the [`Transformation`](@ref) applied to the rays generated by the camera.
- `screen_distance::Float32`: tells how much far from the eye of the observer is the screen and it influences the FOV (field-of-view).

See also: [`fire_ray(::PerspectiveCamera, ::Float32, ::Float32)`](@ref), [`aperture_deg`](@ref)
"""
Base.@kwdef struct PerspectiveCamera <: Camera
    aspect_ratio::Float32 = 1f0
    transformation::Transformation = Transformation()
    screen_distance::Float32 = 1f0
end

@doc """
    PerspectiveCamera(aspect_ratio::Float32, transformation::Transformation, screen_distance::Float32)

Constructor for an [`PerspectiveCamera`](@ref) instance.
""" PerspectiveCamera(::Float32, ::Transformation, ::Float32)

@doc """
    PerspectiveCamera(; aspect_ratio::Float32 = 1f0,
                        transformation::Transformation = Transformation(),
                        screen_distance::Float32 = 1f0)

Keyword-based constructor for a [`PerspectiveCamera`](@ref) instance.

If no parameter is specified, it return a camera with square aspect ratio, an identity transformation, and a
screen distance of 1, giving a FOV of 90°.
""" PerspectiveCamera(; ::Float32, ::Transformation, ::Float32)


##########
# Methods


"""
    fire_ray(camera::OrthogonalCamera, u::Float32, v::Float32)

Fire a [`Ray`](@ref) through an [`OrthogonalCamera`](@ref) at a position ``(u, v)`` on the screen,
using an orthogonal projection.

Parameters `u` and `v` are bound between 0 and 1:

    (0, 1)                            (1, 1)
        +------------------------------+
        |                              |
        |                              |
        |                              |
        +------------------------------+
    (0, 0)                            (1, 0)
"""
function fire_ray(camera::OrthogonalCamera, u::Float32, v::Float32)
    camera.transformation * Ray(Point(-1f0, (1f0 - 2u) * camera.aspect_ratio, 2v - 1f0),
                                VEC_X,
                                tmin = 1f0)
end

"""
    fire_ray(camera::PerspectiveCamera, u::Float32, v::Float32)

Fire a [`Ray`](@ref) through a [`PerspectiveCamera`](@ref) at a position ``(u, v)`` on the screen,
using a perspective projection.

Parameters `u` and `v` are bound between 0 and 1:

    (0, 1)                            (1, 1)
        +------------------------------+
        |                              |
        |                              |
        |                              |
        +------------------------------+
    (0, 0)                            (1, 0)
"""
function fire_ray(camera::PerspectiveCamera, u::Float32, v::Float32)
    camera.transformation * Ray(Point(-camera.screen_distance, 0f0, 0f0),
                                Vec(camera.screen_distance, (1f0 - 2u) * camera.aspect_ratio, 2v - 1f0),
                                tmin = 1f0)
end

"""
    aperture_deg(camera::PerspectiveCamera)

Compute the FOV of the camera in degrees for a [`PerspectiveCamera`](@ref).

# Examples

FOV for a camera with screen distance of 1 and aspect ratio of 1:

```jldoctest
julia> aperture_deg(PerspectiveCamera())
90.0f0
```

FOV for a camera with screen distance of 1 and aspect ratio of 16/9:

```jldoctest
julia> aperture_deg(PerspectiveCamera(aspect_ratio = 16//9))
58.715508f0
```
"""
aperture_deg(camera::PerspectiveCamera) = 2 * rad2deg(atan(camera.screen_distance, camera.aspect_ratio))
