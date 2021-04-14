# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   geometry.jl
# description:
#   Implementation of the geometry required for the generation
#   and manipulation of a 3D scene.
abstract type RaytracerGeometry end

struct Vec{T<:Real} <: RaytracerGeometry
    x::T
    y::T
    z::T
end

struct Point{T<:Real} <: RaytracerGeometry
    x::T
    y::T
    z::T
end
