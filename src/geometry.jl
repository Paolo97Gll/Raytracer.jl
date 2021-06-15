# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Implementation of the geometry required by the renderer (manipulation of 3D scenes, cameras, rays, ...)


#####################################################################


"""
    Vec <: StaticArrays.FieldVector{3, Float32}

A vector in 3D space with 3 fields `x`, `y`, and `z` of type `Float32`.

For inherited properties and constructors see `StaticArrays.FieldVector`.
"""
struct Vec <: FieldVector{3, Float32}
    x::Float32
    y::Float32
    z::Float32
end

@doc """
    Vec(x::Float32, y::Float32, z::Float32)

Constructor for a [`Vec`](@ref) instance.
""" Vec(::Float32, ::Float32, ::Float32)

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

A pseudo-vector in 3D space with 3 fields `x`, `y`, and `z` of type `Float32`.
The parameter `V` tells if the normal is normalized or not.

For inherited properties and constructors see `StaticArrays.FieldVector`.
"""
struct Normal{V} <: FieldVector{3, Float32}
    x::Float32
    y::Float32
    z::Float32
end

@doc """
    Normal{V}(x::Float32, y::Float32, z::Float32)

Constructor for a [`Normal`](@ref) instance.
""" Normal{V}(::Float32, ::Float32, ::Float32)

"""
    Normal(x, y, z)

Construct a non-normalized [`Normal{false}`](@ref) with given coordinates. All values are converted in `Float32`.

# Examples

```jldoctest
julia> Normal(1.2, 3.3, 5)
Normal with eltype Float32, not normalized
x = 1.2, y = 3.3, z = 5.0
```
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

Normalize `n` and return a [`Normal{true}`](@ref). If `n` is already a `Normal{true}` instance, no normalization is computed and `n` is returned.

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

Compute the squared norm of a [`Normal`](@ref). If `n` is a `Normal{true}` instance then `1f0` is returned.

# Examples

```jldoctest
julia> n = Normal(1, 2, 3);

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

@doc """
    Point(p::AbstractVector)

Constructor for a [`Point`](@ref) instance.
""" Point(::AbstractVector)

"""
    Point(x, y, z)

Construct a [`Point`](@ref) with given coordinates. All values are converted in `Float32`.

# Examples

```jldoctest
julia> Point(1.2, 3.3, 5)
Point with eltype Float32
x = 1.2, y = 3.3, z = 5.0
```
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

Check if two points are close.

# Examples

```jldoctest
julia> p = Point(1, 2, 3);

julia> p ≈ Point(1, 2, 3)
true

julia> p ≈ Point(0, 0, 0)
false
```
"""
(≈)(p1::Point, p2::Point) = p1.v ≈ p2.v

"""
    -(p1::Point, p2::Point)

Return the elementwise difference of two [`Point`](@ref) as an instance of [`Vec`](@ref).

# Examples

```jldoctest
julia> Point(1, 2, 3) - Point(4, 5, 6)
Vec with eltype Float32
x = -3.0, y = -3.0, z = -3.0
```
"""
(-)(p1::Point, p2::Point) = Vec(p1.v - p2.v)

"""
    -(p::Point, v::Vec)

Return the elementwise difference between a [`Point`](@ref) and a [`Vec`](@ref) as an instance of `Point`.

# Examples

```jldoctest
julia> Point(1, 2, 3) - Vec(4, 5, 6)
Point with eltype Float32
x = -3.0, y = -3.0, z = -3.0
```
"""
(-)(p::Point, v::Vec) = Point(p.v - v)

"""
    +(p::Point, v::Vec)

Return the elementwise sum between a [`Point`](@ref) and a [`Vec`](@ref) as an instance of `Point`.

# Examples

```jldoctest
julia> Point(1, 2, 3) + Vec(4, 5, 6)
Point with eltype Float32
x = 5.0, y = 7.0, z = 9.0
```
"""
(+)(p::Point, v::Vec) = Point(p.v + v)

"""
    *(p::Point, s...)

Multiplication operator. `x * y * z * ...`` calls this function with all arguments, i.e. `*(x, y, z, ...)`.

Return a [`Point`](@ref).

# Examples

```jldoctest
julia> Point(1, 2, 3) * 2 * 3
Point with eltype Float32
x = 6.0, y = 12.0, z = 18.0
```
"""
(*)(p::Point, s...) = (*)(p.v, s...) |> Point

"""
    convert(::Type{Vec}, p::Point)
    convert(::Type{Normal}, p::Point)

Convert a [`Point`](@ref) into the specified type ([`Vec`](@ref) or [`Normal{false}`](@ref)).
"""
convert(::Type{Vec}, p::Point) = Vec(p.v)
convert(::Type{Normal}, p::Point) = Normal{false}(p.v)


#####################################################################


"""
    Vec2D

Alias to `SVector{2, Float32}`, used for uv mapping on shapes.
"""
const Vec2D = SVector{2, Float32}


#####################################################################


"""
    VEC_X

A unitary [`Vec`](@ref) along the x-axis.
"""
const VEC_X = Vec(1f0, 0f0, 0f0)

"""
    VEC_Y

A unitary [`Vec`](@ref) along the y-axis.
"""
const VEC_Y = Vec(0f0, 1f0, 0f0)

"""
    VEC_Z

A unitary [`Vec`](@ref) along the z-axis.
"""
const VEC_Z = Vec(0f0, 0f0, 1f0)

"""
    NORMAL_X

A unitary and normalized [`Normal{true}`](@ref) along the x-axis.
"""
const NORMAL_X = Normal{true}(1f0, 0f0, 0f0)

"""
    NORMAL_Y

A unitary and normalized [`Normal{true}`](@ref) along the y-axis.
"""
const NORMAL_Y = Normal{true}(0f0, 1f0, 0f0)

"""
    NORMAL_Z

A unitary and normalized [`Normal{true}`](@ref) along the z-axis.
"""
const NORMAL_Z = Normal{true}(0f0, 0f0, 1f0)

"""
    NORMAL_X_false

A unitary and non-normalized [`Normal{false}`](@ref) along the x-axis.
"""
const NORMAL_X_false = Normal{false}(1f0, 0f0, 0f0)

"""
    NORMAL_Y_false

A unitary and non-normalized [`Normal{false}`](@ref) along the y-axis.
"""
const NORMAL_Y_false = Normal{false}(0f0, 1f0, 0f0)

"""
    NORMAL_Z_false

A unitary and non-normalized [`Normal{false}`](@ref) along the z-axis.
"""
const NORMAL_Z_false = Normal{false}(0f0, 0f0, 1f0)

"""
    ORIGIN

A [`Point`](@ref) representing the origin of the frame of reference.
"""
const ORIGIN = Point(0f0, 0f0, 0f0)


#######################################################


"""
    create_onb_from_z(input_normal::Normal)

Create an orthonormal base from a input [`Normal`](@ref) representing the z-axis using the
[Duff et al. 2017](https://graphics.pixar.com/library/OrthonormalB/paper.pdf) algorithm.

# Examples

```jldoctest
julia> n = Normal(0,0,5);

julia> nn = normalize(Normal(0,0,5));

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
    normalized_dot(v1::AbstractVector, v2::AbstractVector)

Normalize `v1` and `v2` and then compute the dot product.
"""
normalized_dot(v1::AbstractVector, v2::AbstractVector) = normalize(v1) ⋅ normalize(v2)
