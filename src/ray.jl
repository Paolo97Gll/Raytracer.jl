# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Ray of light propagating in space for the raytracing algorithms


"""
    struct Ray

A ray of light propagating in space.

# Members

- `origin::Point`: the ([`Point`](@ref)) where the ray originated.
- `dir::Vec`: a ([`Vec`](@ref)) representing the direction along which this ray propagates.
- `tmin::Float32`: the minimum distance travelled by the ray is this number times `dir`.
- `tmax::Float32`: the maximum distance travelled by the ray is this number times `dir`.
- `depth::Int`: number of times this ray was reflected/refracted.

See also: [`Ray(::Float32)`](@ref)
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

@doc """
    Ray(origin::Point, dir::Vec, tmin::Float32, tmax::Float32, depth::Int)

Constructor for a [`Ray`](@ref) instance.
""" Ray(::Point, ::Vec, ::Float32, ::Float32, ::Int)

"""
    Ray(origin::Point, dir::Vec
        ; tmin::Float32 = 1f-5,
          tmax::Float32 = Inf32,
          depth::Int = 0)

Constructor for a [`Ray`](@ref) instance.
"""
Ray(origin::Point, dir::Vec; tmin::Float32 = 1f-5, tmax::Float32 = Inf32, depth::Int = 0) = Ray(origin, dir, tmin, tmax, depth)

@doc raw"""
    (r::Ray)(t::Float32)

Return a [`Point`](@ref) lying on the given [`Ray`](@ref) at `t`.

An instance of `Ray` can be called as a function returning a `Point` given the position parameter `t`:

```math
\mathrm{ray\_origin} + \mathrm{ray\_direction} \cdot t
```

Argument `t` must be included between `r.tmin` and `r.tmax` or be equal to 0.
If `t` is zero, then the returned point is the origin of `r`.

# Examples

```jldoctest
julia> ray = Ray(ORIGIN, VEC_X)
Ray
 ↳ origin = Point(0.0, 0.0, 0.0)
 ↳ dir    = Vec(1.0, 0.0, 0.0)
 ↳ tmin   = 1.0e-5
 ↳ tmax   = Inf
 ↳ depth  = 0

julia> ray(5f0)
Point with eltype Float32
x = 5.0, y = 0.0, z = 0.0
```
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

"""
    ≈(r1::Ray, r2::Ray)

Check if two [`Ray`](@ref) represent the same ray of light or not.
"""
(≈)(r1::Ray, r2::Ray) = (r1.origin ≈ r2.origin) && (r1.dir ≈ r2.dir)

"""
    *(t::Transformation, r::Ray)

Transform a [`Ray`](@ref) with the given [`Transformation`](@ref).

# Examples

```jldoctest
julia> ray = Ray(ORIGIN, VEC_X)
Ray
 ↳ origin = Point(0.0, 0.0, 0.0)
 ↳ dir    = Vec(1.0, 0.0, 0.0)
 ↳ tmin   = 1.0e-5
 ↳ tmax   = Inf
 ↳ depth  = 0

julia> Transformation() * ray
Ray
 ↳ origin = Point(0.0, 0.0, 0.0)
 ↳ dir    = Vec(1.0, 0.0, 0.0)
 ↳ tmin   = 1.0e-5
 ↳ tmax   = Inf
 ↳ depth  = 0

julia> translation(2,4,-6) * ray
Ray
 ↳ origin = Point(2.0, 4.0, -6.0)
 ↳ dir    = Vec(1.0, 0.0, 0.0)
 ↳ tmin   = 1.0e-5
 ↳ tmax   = Inf
 ↳ depth  = 0
```
"""
(*)(t::Transformation, r::Ray) = Ray(t*r.origin, t*r.dir, r.tmin, r.tmax, r.depth)
