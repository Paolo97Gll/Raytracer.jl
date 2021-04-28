# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   cameras.jl
# description:
#   This file implement the Camera abstract type and the two derivating
#   concrete types, OrthogonalCamera and PerspectiveCamera


"""
    Camera

An abstract type representing an observer.
"""
abstract type Camera end


"""
    OrthogonalCamera

A camera implementing an orthogonal 3D → 2D projection.

This type implements an observer seeing the world through an orthogonal projection.

Members:
- `aspect_ratio` ([`Real`](@ref)): defines how larger than the height is the image (16/9, 4/3, ...),
you can use julia rational like `16//9`.
- `transformation` ([`Transformation`](@ref)): define the transformation applied to the rays generated by the camera.
"""
struct OrthogonalCamera <: Camera
    aspect_ratio::Real
    transformation::Transformation
    OrthogonalCamera(aspect_ratio::Real = 1, transformation = Transformation{Bool}()) = new(aspect_ratio, transformation)
end


"""
    PerspectiveCamera

A camera implementing a perspective 3D → 2D projection.

This type implements an observer seeing the world through a perspective projection.

Members:
- `screen_distance` ([`Real`](@ref)): tells how much far from the eye of the observer is the screen
and it influences the FOV.
- `aspect_ratio` ([`Real`](@ref)): defines how larger than the height is the image (16/9, 4/3, ...), 
you can use julia rational like `16//9`.
- `transformation` ([`Transformation`](@ref)): define the transformation applied to the rays generated by the camera.
"""
struct PerspectiveCamera <: Camera
    screen_distance::Real
    aspect_ratio::Real
    transformation::Transformation
    PerspectiveCamera(screen_distance::Real = 1, aspect_ratio::Real = 1, transformation = Transformation{Bool}()) = new(screen_distance, aspect_ratio, transformation)
end


#####################################################################


"""
    fire_ray(camera, u, v, T = Float32)

Fire a [`Ray`](@ref) through the [`Camera`](@ref) at a position (u,v) on the screen.

Parameters `u` and `v` are bound between `0` and `1`:

    (0, 1)                            (1, 1)
        +------------------------------+
        |                              |
        |                              |
        |                              |
        +------------------------------+
    (0, 0)                            (1, 0)

Type parameter `T` is passed onto the [`Ray`](@ref) constructor. Default type is `Float32`.
"""
function fire_ray(camera::OrthogonalCamera, u, v, T::Type{<:AbstractFloat} = Float32)
    0 <= u <= 1 || throw(ArgumentError("argument `u` must be bound to the range [0, 1]: got $u"))
    0 <= v <= 1 || throw(ArgumentError("argument `v` must be bound to the range [0, 1]: got $v"))
    origin = Point(-1.0, (1.0 - 2 * u) * camera.aspect_ratio, 2 * v - 1)
    camera.transformation * Ray{T}(origin, VEC_X, tmin = 1)
end

function fire_ray(camera::PerspectiveCamera, u, v, T::Type{<:AbstractFloat} = Float32)
    0 <= u <= 1 || throw(ArgumentError("argument `u` must be bound to the range [0, 1]: got $u"))
    0 <= v <= 1 || throw(ArgumentError("argument `v` must be bound to the range [0, 1]: got $v"))
    origin = Point(-camera.distance, 0, 0)
    direction = Vec(camera.distance, (1.0 - 2 * u) * camera.aspect_ratio, 2 * v - 1)
    camera.transformation * Ray{T}(origin, direction, tmin = 1)
end


"""
    aperture_deg(camera)

Compute the FOV of the camera in degrees. `camera` must be a [`PerspectiveCamera`](@ref) instance.
"""
aperture_deg(camera::PerspectiveCamera) = 2.0 * rad2deg(atan(camera.screen_distance, camera.aspect_ratio))
