# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Ray of light propagating in space for the raytracing algorithms
# TODO write docstrings


"""
    Ray

A ray of light propagating in space.

Members:
- `origin` ([`Point`](@ref)): the 3D point where the ray originated
- `dir` ([`Vec`](@ref)): the 3D direction along which this ray propagates
- `tmin` (`T`): the minimum distance travelled by the ray is this number times `dir`
- `tmax` (`T`): the maximum distance travelled by the ray is this number times `dir`
- `depth` (`Int`): number of times this ray was reflected/refracted
"""
struct Ray
    origin::Point
    dir::Vec
    tmin::Float32
    tmax::Float32
    depth::Int

    function Ray(origin::Point, dir::Vec, tmin::Float32, tmax::Float32, depth::Int)
        tmin < tmax || throw(ArgumentError("`tmin >= tmax` is not allowed: `tmin = $tmin`, `tmax = $tmax`"))
        new(origin, dir, tmin, tmax, depth)
    end
end

"""
    Ray(origin, dir; tmin = 1e-5, tmax = typemax(T), depth = 0)

Construct an instance of [`Ray`](@ref) with `tmin`, tmax
"""
Ray(origin::Point, dir::Vec; tmin::Float32 = 1f-5, tmax::Float32 = typemax(Float32), depth::Int = 0) = Ray(origin, dir, tmin, tmax, depth)

"""
    (r::Ray)(t::Real)

Return `Point` lying on the given `Ray` at `t`.

An instance of [`Ray`](@ref) can be called as a function returning a `Point` given the position parameter `t`.
Argument `t` must be included between `r.tmin` and `r.tmax` or be equal to `0`.
If `t == 0` then the returned point is the origin of the `Ray`.
"""
function (r::Ray)(t::Float32)
    t == 0 && return r.origin
    r.tmin <= t <= r.tmax || throw(ArgumentError("argument `t` must have a value between `r.tmin = $(r.tmin)` and `r.tmax = $(r.tmax)`: got `t = $t`"))
    r.origin + r.dir * t
end


################
# Miscellaneous


function show(io::IO, ::MIME"text/plain", ray::T) where {T <: Ray}
    print(io, T)
    fns = fieldnames(T)
    n = maximum(fns .|> String .|> length)
    for fieldname ∈ fns
        println(io)
        print(io, " ↳ ", rpad(fieldname, n), " = ", getfield(ray, fieldname))
    end
end

eltype(::Ray) = Float32
eltype(::Type{Ray}) = Float32

(≈)(r1::Ray, r2::Ray) = (r1.origin ≈ r2.origin) && (r1.dir ≈ r2.dir)

(*)(t::Transformation, r::Ray) = Ray(t*r.origin, t*r.dir, r.tmin, r.tmax, r.depth)
