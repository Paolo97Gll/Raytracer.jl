# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Implementation of the geometry required by the renderer (manipulation of 3D scenes, cameras, rays, ...)
# TODO write docstrings


#####################################################################


"""
    Vec <: StaticArrays.FieldVector{3, Float32}

A vector in 3D space.

For inherited properties and constructors see [`StaticArrays.FieldVector`](@ref).
"""
struct Vec <: FieldVector{3, Float32}
    x::Float32
    y::Float32
    z::Float32
end

similar_type(::Type{<:Vec}, ::Type{Float32}, s::Size{(3,)}) = Vec

################
# Miscellaneous

function show(io::IO, a::Vec)
    print(io, typeof(a), "(", join((string(el) for el ∈ a), ", "), ")")
end

function show(io::IO, ::MIME"text/plain", a::Vec)
    print(io, "Vec with eltype $(eltype(a))\n", join(("$label = $el" for (label, el) ∈ zip((:x, :y, :z), a)), ", "))
end

norm²(v::Vec) = sum(el -> el^2, v)

#####################################################################

"""
    Normal{V} <: StaticArrays.FieldVector{3, Float32}

A pseudo-vector in 3D space.

For inherited properties and constructors see [`StaticArrays.FieldVector`](@ref).
"""
struct Normal{V} <: FieldVector{3, Float32}
    x::Float32
    y::Float32
    z::Float32
end

Normal(x, y, z) = Normal{false}(convert(Float32, x), convert(Float32, y), convert(Float32, z))

similar_type(::Type{<:Normal}, ::Type{Float32}, s::Size{(3,)}) = Normal

################
# Miscellaneous

function show(io::IO, a::Normal)
    print(io, typeof(a), "(", join((string(el) for el ∈ a), ", "), ")")
end

function show(io::IO, ::MIME"text/plain", n::Normal{V}) where {V}
    print(io, "Normal with eltype $(eltype(n)), ", V ? "normalized" : "not normalized", "\n",
          join(("$label = $el" for (label, el) ∈ zip((:x, :y, :z), n)), ", "))
end

normalize(n::Normal{false}) = Normal{true}(normalize(SVector{3}(n)))
norm²(n::Normal{false}) = sum(el -> el^2, n)

normalize(n::Normal{true}) = n
norm(::Normal{true}) = 1f0
norm²(::Normal{true}) = 1f0


#####################################################################


"""
    Point

A point in a 3D space. Implemented as a wrapper struct around a `SVector{3, Float32}`.
"""
struct Point
    v::SVector{3, Float32}

    function Point(p::AbstractVector)
        size(p) == (3,) || throw(ArgumentError("argument 'p' has size = $(size(p)) but 'Point' requires an argument of size = (3,)"))
        new(SVector{3}(p))
    end
end

"""
    Point(x, y, z)
    Point(p::AbstractVector)

Construct a `Point` with given coordinates.

If an `AbstractVector` is provided as argument it must have a size = (3,)

# Examples

```jldoctest
julia> Point(1, 2, 3)
Point with eltype Int64
x = 1, y = 2, z = 3

julia> Point([1, 2, 3])
Point with eltype Int64
x = 1, y = 2, z = 3
```
"""
Point(x, y, z) = Point(SVector(convert(Float32, x), convert(Float32, y), convert(Float32, z)))

################
# Miscellaneous

eltype(::Point) = Float32
eltype(::Type{Point}) = Float32

length(::Point) = 3
firstindex(::Point) = 1
lastindex(p::Point) = 3
getindex(p::Point, i::Integer) = p.v[i]
iterate(p::Point, state = 1) = state > 3 ? nothing : (p[state], state +1)

function show(io::IO, p::Point)
    print(io, typeof(p), "(", join((string(el) for el ∈ p), ", "), ")")
end

function show(io::IO, ::MIME"text/plain", p::Point)
    print(io, Point, " with eltype $(eltype(p))\n", join(("$label = $el" for (label, el) ∈ zip((:x, :y, :z), p)), ", "))
end

(≈)(p1::Point, p2::Point) = p1.v ≈ p2.v

(-)(p1::Point, p2::Point) = Vec(p1.v - p2.v)
(-)(p::Point, v::Vec) = Point(p.v - v)

(+)(p::Point, v::Vec) = Point(p.v + v)

(*)(p::Point, s...) = (*)(p.v, s...) |> Point

convert(::Type{Vec}, p::Point) = Vec(p.v)
convert(::Type{Normal}, p::Point)= Normal{false}(p.v)


#####################################################################


const Vec2D = SVector{2, Float32}

const VEC_X = Vec(1f0, 0f0, 0f0)
const VEC_Y = Vec(0f0, 1f0, 0f0)
const VEC_Z = Vec(0f0, 0f0, 1f0)

const NORMAL_X = Normal{true}(1f0, 0f0, 0f0)
const NORMAL_Y = Normal{true}(0f0, 1f0, 0f0)
const NORMAL_Z = Normal{true}(0f0, 0f0, 1f0)

const ORIGIN = Point(0f0, 0f0, 0f0)


#######################################################


function create_onb_from_z(input_normal::Normal)
    normal = normalize(input_normal)

    sign = copysign(1f0, normal.z)

    a = -1f0 / (sign + normal.z)
    b = normal.x * normal.y * a

    e1 = Vec(1f0 + sign * normal.x * normal.x * a, sign * b, -sign * normal.x)
    e2 = Vec(b, sign + normal.y * normal.y * a, -normal.y)

    (e1, e2, convert(Vec, normal))
end


normalized_dot(v1::Vec, v2::Vec) = normalize(v1) ⋅ normalize(v2)
normalized_dot(n1::Normal, n2::Normal) = normalize(n1) ⋅ normalize(n2)
