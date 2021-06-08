# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Extension of ColorTypes.RGB for color manipulation


#############
# Operations


"""
    +(c1::RGB, c2::RGB)

Return the elementwise sum of two colors.

# Examples

```jldoctest
julia> c1 = RGB(1f0, 2f0, 3f0)
RGB color with eltype Float32
R: 1.0, G: 2.0, B: 3.0

julia> c2 = RGB(4f0, 5f0, 6f0)
RGB color with eltype Float32
R: 4.0, G: 5.0, B: 6.0

julia> c1 + c2
RGB color with eltype Float32
R: 5.0, G: 7.0, B: 9.0
```
"""
(+)(c1::RGB, c2::RGB) = RGB(c1.r + c2.r, c1.g + c2.g, c1.b + c2.b)

"""
    -(c1::RGB, c2::RGB)

Return the elementwise difference of two colors.

# Examples

```jldoctest
julia> c1 = RGB(1f0, 2f0, 3f0)
RGB color with eltype Float32
R: 1.0, G: 2.0, B: 3.0

julia> c2 = RGB(4f0, 5f0, 6f0)
RGB color with eltype Float32
R: 4.0, G: 5.0, B: 6.0

julia> c1 - c2
RGB color with eltype Float32
R: -3.0, G: -3.0, B: -3.0
```
"""
(-)(c1::RGB, c2::RGB) = RGB(c1.r - c2.r, c1.g - c2.g, c1.b - c2.b)

"""
    *(scalar::Number, c::RGB)
    *(c::RGB, scalar::Number)

Return a `RGB{T}` color with each component multiplied by `scalar`.

# Examples

```jldoctest
julia> scalar = 2.0
2.0

julia> c = RGB(4f0, 5f0, 6f0)
RGB color with eltype Float32
R: 4.0, G: 5.0, B: 6.0

julia> scalar * c
RGB color with eltype Float32
R: 8.0, G: 10.0, B: 12.0

julia> c * scalar
RGB color with eltype Float32
R: 8.0, G: 10.0, B: 12.0
```

```jldoctest
julia> scalar = 2.0
2.0

julia> c = RGB(4.0, 5.0, 6.0)
RGB color with eltype Float64
R: 4.0, G: 5.0, B: 6.0

julia> scalar * c
RGB color with eltype Float64
R: 8.0, G: 10.0, B: 12.0
```

Note that the eltype of RGB is mantained.
"""
(*)(scalar::Number, c::RGB{T}) where {T} = RGB{T}(scalar * c.r, scalar * c.g, scalar * c.b)
(*)(c::RGB, scalar::Number) = scalar * c

"""
    *(c1::RGB, c2::RGB)

Return the elementwise product of two colors.

# Examples

```jldoctest
julia> c1 = RGB(1f0, 2f0, 3f0)
RGB color with eltype Float32
R: 1.0, G: 2.0, B: 3.0

julia> c2 = RGB(4f0, 5f0, 6f0)
RGB color with eltype Float32
R: 4.0, G: 5.0, B: 6.0

julia> c1 * c2
RGB color with eltype Float32
R: 4.0, G: 10.0, B: 18.0
```
"""
(*)(c1::RGB, c2::RGB) = RGB(c1.r * c2.r, c1.g * c2.g, c1.b * c2.b)

"""
    ≈(c1::RGB, c2::RGB)

Check if two colors are close.

# Examples

```jldoctest
julia> c1 = RGB(1f0, 2f0, 3f0)
RGB color with eltype Float32
R: 1.0, G: 2.0, B: 3.0

julia> c2 = RGB(4f0, 5f0, 6f0)
RGB color with eltype Float32
R: 4.0, G: 5.0, B: 6.0

julia> c1 * c2 ≈ RGB(4f0, 10f0, 18f0)
true

julia> c1 * c2 ≈ RGB(0f0, 0f0, 0f0)
false
```
"""
(≈)(c1::RGB, c2::RGB) = c1.r ≈ c2.r &&
                        c1.g ≈ c2.g &&
                        c1.b ≈ c2.b


#############
# Iterations


length(::RGB) = 3

firstindex(::RGB) = 1

lastindex(c::RGB) = 3

# Since there is no standard that specifies the order in which the colors
# should be reported, here we use the convention whereby the colors should
# be reported in the RGB order (first R, then G, and finally B).
function getindex(c::RGB, i::Integer)
    if i == 1
        return c.r
    elseif i == 2
        return c.g
    elseif i == 3
        return c.b
    else
        throw(BoundsError(c, i))
    end
end

getindex(c::RGB, i::CartesianIndex{1}) = getindex(c, Tuple(i)[1])
# setindex! not implemented since RGB is immutable

iterate(c::RGB, state = 1) = state > 3 ? nothing : (c[state], state +1)


###############
# Broadcasting


# Broadcasting a function `f` on a series of arguments `xs` (ie. `f.(xs...)`) is equivalent to writing
# the following: `materialize(broadcasted(combine_styles(map(broadcastable, xs)), f, xs...))`
# Let's analyze what each of these functions does and why each of the following methods is needed

# Let's start with broadcastable: broadcasting maps its arguments so that each argument is transformed
# into a type supporting indexing and the method `axes`, and thus being able to be converted into an
# array-like type. We'll trick the broadcasting process into thinking this is the case for `RGB` so that
# `broadcastable` will return its argument when it is applied to an `RGB`

axes(::RGB) = (OneTo(3),)

broadcastable(c::RGB) = c
broadcastable(::Type{RGB}) = RGB # broadcastable is also applied to types

# Then the result of the previous mapping is passed onto the function `combine_styles`, which
# relies on calls to the constructor of `BroadcastStyle`. We need to create a `BroadcastStyle`
# exclusive to `RGB` so that we can then specialize other methods that are fed `BroadcastStyle`s

struct RGBBroadcastStyle <: BroadcastStyle end

# Then we specialize the constructor from instances of `RGB`

BroadcastStyle(::Type{<:RGB}) = RGBBroadcastStyle()

# And the constructor that combines the `RGBBroadcastStyle` with any other `BroadcastStyle`
# we want our style to have precedence over any other so that if an `RGB` type is present among
# the arguments of broadcasting the result will be of type `RGB`

BroadcastStyle(::RGBBroadcastStyle, ::BroadcastStyle) = RGBBroadcastStyle()

# The call to `materialize` returns a call to `copy`, which by default is specialized for array-like types
# we then have to implement a method that treats any `Broadcasted` type with our custom `RGBBroadcastStyle`
# in an appropriate way.

@inline function copy(bc::Broadcasted{RGBBroadcastStyle})
    ElType = combine_eltypes(bc.f, bc.args)
    if ElType <: Fractional # IF ElType instances can be stored in a RGB instance
        # the call to `convert` to a `Broadcasted` type of style `Nothing` computes
        # the result of the broadcasting and stores it into an array. splatting this
        # array into an `RGB` constructor gives us the desired result
        return RGB{ElType}(convert(Broadcasted{Nothing}, bc)...)
    else #IF ElType instances cannot be stored in a RGB instance
        return copy(convert(Broadcasted{Broadcast.DefaultArrayStyle{ElType}}, bc))
    end
end


################
# Miscellaneous


show(io::IO, c::RGB) = print(io, "($(c.r) $(c.g) $(c.b))")

function show(io::IO, ::MIME"text/plain", c::RGB{T}) where {T}
    print(io, "RGB color with eltype $T\n", "R: $(c.r), G: $(c.g), B: $(c.b)")
end

@doc raw"""
    luminosity(c::RGB)

Return the mean value between the maximum component and the minumum component of a color:

```math
\frac{max(c) + min(c)}{2}
```

# Examples

```jldoctest
julia> luminosity(RGB(1f0, 2f0, 3f0))
2.0f0
```
"""
luminosity(c::RGB) = (max(c...) + min(c...)) / 2

@doc raw"""
    clamp(c::RGB)

Return a clamped `RGB{T}` color, with each component `x` obtained with the formula:

```math
\frac{x}{1 + x}
```

# Examples

```jldoctest
julia> clamp(RGB(1f0, 2f0, 3f0))
RGB color with eltype Float32
R: 0.5, G: 0.6666667, B: 0.75
```
"""
clamp(c::RGB{T}) where {T} = RGB{T}(map(x -> x / (1f0 + x), c)...)

@doc raw"""
    γ_correction(c::RGB, γ::Number)

Return a `RGB{T}` color, with each component `x` corrected with the formula:

```math
x^{\frac{1}{\gamma}}
```

# Examples

```jldoctest
julia> c = RGB(1f0, 2f0, 3f0)
RGB color with eltype Float32
R: 1.0, G: 2.0, B: 3.0

julia> γ_correction(c, 1)
RGB color with eltype Float32
R: 1.0, G: 2.0, B: 3.0

julia> γ_correction(c, 0.8)
RGB color with eltype Float32
R: 1.0, G: 2.3784142, B: 3.948222

julia> γ_correction(c, 2.4)
RGB color with eltype Float32
R: 1.0, G: 1.3348398, B: 1.580522
```
"""
γ_correction(c::RGB{T}, γ::Number) where {T} = RGB{T}(map(x -> x^(1f0 / γ), c)...)

eltype(::RGB{T}) where {T} = T

function zero(T::Type{<:RGB})
    z = zero(eltype(T))
    RGB(z, z, z)
end

zero(c::RGB) = zero(typeof(c))

function one(T::Type{<:RGB})
    z = one(eltype(T))
    RGB(z, z, z)
end

one(c::RGB) = one(typeof(c))

const BLACK = zero(RGB{Float32})
const WHITE = one(RGB{Float32})
const RED = RGB(1f0, 0f0, 0f0)
const GREEN = RGB(0f0, 1f0, 0f0)
const BLUE = RGB(0f0, 0f0, 1f0)
const CYAN = RGB(0f0, 1f0, 1f0)
const MAGENTA = RGB(1f0, 0f0, 1f0)
const YELLOW = RGB(1f0, 1f0, 0f0)
