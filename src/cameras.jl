# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Implementation of the Camera abstract type and the two derivating concrete types,
# OrthogonalCamera and PerspectiveCamera


"""
    Camera

An abstract type representing an observer.
"""
abstract type Camera end


###################
# OrthogonalCamera


"""
    OrthogonalCamera

A camera implementing an orthogonal 3D → 2D projection.

# Members

- `aspect_ratio::Float32`: defines how larger than the height is the image (16/9, 4/3, ...).
- `transformation::Transformation`: define the transformation applied to the rays generated by the camera.

See also: [`Transformation`](@ref)
"""
Base.@kwdef struct OrthogonalCamera <: Camera
    aspect_ratio::Float32 = 1f0
    transformation::Transformation = Transformation()
end

@doc """
    OrthogonalCamera(; aspect_ratio::Float32 = 1f0,
                       transformation::Transformation = Transformation())

If no parameter is specified, it return a camera with square aspect ratio and an identity transformation.

See also: [`OrthogonalCamera`](@ref), [`Transformation`](@ref)
""" OrthogonalCamera(; ::Float32, ::Transformation)

"""
    fire_ray(camera<:Camera, u::Float32, v::Float32)

Fire a [`Ray`](@ref) through the [`Camera`](@ref) at a position ``(u, v)`` on the screen.

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


####################
# PerspectiveCamera


"""
    PerspectiveCamera

A camera implementing a perspective 3D → 2D projection.

# Members

- `aspect_ratio::Float32`: defines how larger than the height is the image (16/9, 4/3, ...).
- `transformation::Transformation`: define the transformation applied to the rays generated by the camera.
- `screen_distance::Float32`: tells how much far from the eye of the observer is the screen and it influences the FOV (field-of-view).
"""
Base.@kwdef struct PerspectiveCamera <: Camera
    aspect_ratio::Float32 = 1f0
    transformation::Transformation = Transformation()
    screen_distance::Float32 = 1f0
end

@doc """
    PerspectiveCamera(; aspect_ratio::Float32 = 1f0,
                        transformation::Transformation = Transformation(),
                        screen_distance::Float32 = 1f0)

Constructor for a [`PerspectiveCamera`](@ref) instance.
""" PerspectiveCamera(; ::Float32, ::Transformation, ::Float32)

"""
    fire_ray(camera::Camera, u::Float32, v::Float32)

Fire a [`Ray`](@ref) through the [`Camera`](@ref) at a position ``(u, v)`` on the screen.

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

Compute the FOV of the camera in degrees for a [PerspectiveCamera](@ref).

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
