# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Implementation of the geometry required by the renderer (manipulation of 3D scenes, cameras, rays, ...)
# TODO write docstrings


#####################################################################


"""
    Vec <: StaticArrays.FieldVector{3, Float32}

A vector in 3D space with field `x`, `y`, and `z`.

For inherited properties and constructors see `StaticArrays.FieldVector`.
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

"""
    norm²(v::Vec)

Compute the squared norm of a [`Vec`](@ref).

# Examples

```jldoctest
julia> norm²(Vec(1, 2, 3))
14.0f0
```
"""
norm²(v::Vec) = sum(el -> el^2, v)

#####################################################################

"""
    Normal{V} <: StaticArrays.FieldVector{3, Float32}

A pseudo-vector in 3D space with field `x`, `y`, and `z`. The parameter `V` tells if the normal is normalized or not.

For inherited properties and constructors see `StaticArrays.FieldVector`.
"""
struct Normal{V} <: FieldVector{3, Float32}
    x::Float32
    y::Float32
    z::Float32
end

"""
    Normal(x, y, z)

Construct a non-normalized [`Normal{false}`](@ref) with given coordinates.
"""
Normal(x, y, z) = Normal{false}(map(x -> convert(Float32, x), (x, y, z)))

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

"""
    normalize(n::Normal)

Normalize `n` and return a `Normal`. If `n` is already normalized, no normalization is computed and `n` is returned.

# Examples

```jldoctest
julia> n = normalize(Normal(1,2,4))
Normal with eltype Float32, normalized
x = 0.21821788, y = 0.43643576, z = 0.8728715

julia> normalize(n)
Normal with eltype Float32, normalized
x = 0.21821788, y = 0.43643576, z = 0.8728715
```
"""
normalize(n::Normal{false}) = Normal{true}(normalize(SVector{3}(n)))
normalize(n::Normal{true}) = n

"""
    norm(n::Normal{true})

Compute the squared norm of a [`Normal{true}`](@ref). Since `n` is already normalized, `1f0` is returned.
"""
norm(::Normal{true}) = 1f0

"""
    norm²(n::Normal)

Compute the squared norm of a [`Normal`](@ref). If `n` is already normalized, `1f0` is returned.

# Examples

```jldoctest
julia> n = Normal(1, 2, 3)
Normal with eltype Float32, not normalized
x = 1.0, y = 2.0, z = 3.0

julia> norm²(n)
14.0f0

julia> norm²(normalize(n))
1.0f0
```
"""
norm²(n::Normal{false}) = sum(el -> el^2, n)
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

Construct a `Point` with given coordinates.
"""
Point(x, y, z) = Point(SVector(map(x -> convert(Float32, x), (x, y, z))))

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

"""
    ≈(p1::Point, p2::Point)

Check if two colors are close.

# Examples

```jldoctest
julia> p = Point(1, 2, 3)
Point with eltype Float32
x = 1.0, y = 2.0, z = 3.0

julia> p ≈ Point(1, 2, 3)
true

julia> p ≈ Point(0, 0, 0)
false
```
"""
(≈)(p1::Point, p2::Point) = p1.v ≈ p2.v

# TODO docstring
(-)(p1::Point, p2::Point) = Vec(p1.v - p2.v)

# TODO docstring
(-)(p::Point, v::Vec) = Point(p.v - v)

# TODO docstring
(+)(p::Point, v::Vec) = Point(p.v + v)

# TODO docstring
(*)(p::Point, s...) = (*)(p.v, s...) |> Point

"""
    convert(::Type{Vec}, p::Point)
    convert(::Type{Normal}, p::Point)

Convert `p` into the specified type.
"""
convert(::Type{Vec}, p::Point) = Vec(p.v)
convert(::Type{Normal}, p::Point) = Normal{false}(p.v)


#####################################################################


# TODO docstring
const Vec2D = SVector{2, Float32}


const VEC_X = Vec(1f0, 0f0, 0f0)
const VEC_Y = Vec(0f0, 1f0, 0f0)
const VEC_Z = Vec(0f0, 0f0, 1f0)

const NORMAL_X = Normal{true}(1f0, 0f0, 0f0)
const NORMAL_Y = Normal{true}(0f0, 1f0, 0f0)
const NORMAL_Z = Normal{true}(0f0, 0f0, 1f0)

const NORMAL_X_false = Normal{false}(1f0, 0f0, 0f0)
const NORMAL_Y_false = Normal{false}(0f0, 1f0, 0f0)
const NORMAL_Z_false = Normal{false}(0f0, 0f0, 1f0)

const ORIGIN = Point(0f0, 0f0, 0f0)


#######################################################


"""
    create_onb_from_z(input_normal::Normal)

Create an orthonormal base from the z-axis using the [Duff et al. 2017](https://graphics.pixar.com/library/OrthonormalB/paper.pdf) algorithm.

As first, `input_normal` is notmalized.

# Examples

```jldoctest
julia> n = Normal(0,0,5)
Normal with eltype Float32, not normalized
x = 0.0, y = 0.0, z = 5.0

julia> nn = normalize(Normal(0,0,5))
Normal with eltype Float32, normalized
x = 0.0, y = 0.0, z = 1.0

julia> create_onb_from_z(n)
(Vec(1.0, -0.0, -0.0), Vec(-0.0, 1.0, -0.0), Vec(0.0, 0.0, 1.0))

julia> create_onb_from_z(nn)
(Vec(1.0, -0.0, -0.0), Vec(-0.0, 1.0, -0.0), Vec(0.0, 0.0, 1.0))
```

Note that `create_onb_from_z(n)` and `create_onb_from_z(nn)` give the same result.
"""
function create_onb_from_z(input_normal::Normal)
    normal = normalize(input_normal)

    sign = copysign(1f0, normal.z)

    a = -1f0 / (sign + normal.z)
    b = normal.x * normal.y * a

    e1 = Vec(1f0 + sign * normal.x * normal.x * a, sign * b, -sign * normal.x)
    e2 = Vec(b, sign + normal.y * normal.y * a, -normal.y)
    e3 = convert(Vec, normal)

    (e1, e2, e3)
end

"""
    normalized_dot(a::Vec, b::Vec)
    normalized_dot(a::Normal, b::Normal)

Normalize `a` and `b` and then compute the dot product.
"""
normalized_dot(v1::Vec, v2::Vec) = normalize(v1) ⋅ normalize(v2)
normalized_dot(n1::Normal, n2::Normal) = normalize(n1) ⋅ normalize(n2)
