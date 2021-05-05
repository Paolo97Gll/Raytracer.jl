# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   ray.jl
# description:
#   This file implement the Ray structure and its methods


"""
    Ray{T}

A ray of light propagating in space.

Members:
- `origin` ([`Point{T}`](@ref)): the 3D point where the ray originated
- `dir` ([`Vec{T}`](@ref)): the 3D direction along which this ray propagates
- `tmin` (`T`): the minimum distance travelled by the ray is this number times `dir`
- `tmax` (`T`): the maximum distance travelled by the ray is this number times `dir`
- `depth` (`Int`): number of times this ray was reflected/refracted
"""
struct Ray{T<:AbstractFloat}
    origin::Point{T}
    dir::Vec{T}
    tmin::T
    tmax::T
    depth::Int

    function Ray(origin::Point{T}, dir::Vec{T}, tmin::T, tmax::T, depth::Int) where {T}
        tmin < tmax || throw(ArgumentError("`tmin >= tmax` is not allowed: `tmin = $tmin`, `tmax = $tmax`"))
        new{T}(origin, dir, tmin, tmax, depth)
    end
end

"""
    Ray{T}(origin, dir; tmin = 1e-5, tmax = typemax(T), depth = 0)

Construct an instance of [`Ray`](@ref) with `tmin`, tmax
"""
Ray(origin::Point{T}, dir::Vec{T}; tmin::T = 1e-5, tmax::T = typemax(T), depth::Int = 0) where {T <: AbstractFloat} = Ray(origin, dir, tmin, tmax, depth)

function Ray{T}(origin::Point, dir::Vec, tmin::Real, tmax::Real, depth::Int) where {T <: AbstractFloat} 
    origin = Point(convert.(T, origin.v))
    dir = Vec{T}(dir)
    tmin = convert(T, tmin)
    tmax = convert(T, tmax)
    Ray(origin, dir, tmin, tmax, depth)
end

function Ray{T}(origin::Point, dir::Vec; tmin::Real = 1e-5, tmax::Real = typemax(T), depth::Int = 0) where {T <: AbstractFloat} 
    origin = Point(convert.(T, origin.v))
    dir = Vec{T}(dir)
    tmin = convert(T, tmin)
    tmax = convert(T, tmax)
    Ray(origin, dir, tmin, tmax, depth)
end

"""
    (r::Ray)(t::Real)

Return `Point` lying on the given `Ray` at `t`.

An instance of [`Ray`](@ref) can be called as a function returning a `Point` given the position parameter `t`.
Argument `t` must be included between `r.tmin` and `r.tmax` or be equal to `0`.
If `t == 0` then the returned point is the origin of the `Ray`.
"""
function (r::Ray)(t::Real)
    t == 0 && return r.origin
    r.tmin <= t <= r.tmax || throw(ArgumentError("argument `t` must have a value between `r.tmin = $(r.tmin)` and `r.tmax = $(r.tmax)`: got `t = $t`"))
    r.origin + r.dir * t
end


eltype(::Ray{T}) where {T} = T
eltype(::Type{Ray{T}}) where {T} = T


(≈)(r1::Ray, r2::Ray) = (r1.origin ≈ r2.origin) && (r1.dir ≈ r2.dir)
(*)(t::Transformation, r::Ray) = Ray{eltype(r)}(t*r.origin, t*r.dir, r.tmin, r.tmax, r.depth)
