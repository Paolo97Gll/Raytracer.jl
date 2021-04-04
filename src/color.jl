# This file include all the extensions to the type ColorTypes.RGB
#
# The current implemented extensions are:
# - OPERATIONS. Implement sum, difference and other operations between RGB types.
# - ITERATIONS. Since an RGB type can be seen as a three-element array, it is 
#   possible to implement the iterations through its elements (r, g and b).
# - BROADCASTING. Same consideration made for the iterations.
# - IO. Utilities for various IO operations, such as printing or writing into
#   a stream.
# - OTHER. Other usefull utilities.
#
# More informations are reported above the single implementation.


##############
# OPERATIONS #
##############


# Element-wise addition of two RGB type instances
(+)(c1::RGB, c2::RGB) = RGB(c1.r + c2.r, c1.g + c2.g, c1.b + c2.b)

# Element-wise subtraction of two RGB type instances
(-)(c1::RGB, c2::RGB) = RGB(c1.r - c2.r, c1.g - c2.g, c1.b - c2.b)

# Scalar multiplication for a RGB type instance
(*)(scalar::Number, c::RGB{T}) where {T} = RGB{T}(scalar * c.r, scalar * c.g, scalar * c.b)

# Scalar multiplication for a RGB type instance
(*)(c::RGB, scalar::Number) = scalar * c

# Element-wise multiplication between two RGB type instances
(*)(c1::RGB, c2::RGB) = RGB(c1.r * c2.r, c1.g * c2.g, c1.b * c2.b)

# Element-wise ≈ operator between two RGB type instances
(≈)(c1::RGB, c2::RGB) = c1.r ≈ c2.r && 
                        c1.g ≈ c2.g &&
                        c1.b ≈ c2.b


##############
# ITERATIONS #
##############


length(::RGB) = 3

firstindex(::RGB) = 1

lastindex(c::RGB) = length(c)


# Since there is no standard that specifies the order in which the colors
# should be reported, here we use the convention whereby the colors should
# be reported in the RGB order (first R, then G and finally B).
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


function iterate(c::RGB, state = 1)
    state > 3 ? nothing : (c[state], state +1)
end


################
# BROADCASTING #
################


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

struct RGBBroadcastStyle <: BroadcastStyle
end

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


######################
# COLOR MANIPULATION #
######################


function luminosity(c::RGB)
    (max(c...) + min(c...)) / 2
end


_clamp(c::RGB) = RGB(map(x -> x / (1+x), c)...)

_γ_correction(c::RGB, γ::Number) = RGB(map(x -> x^(1/γ), c)...)


######
# IO #
######


# Show in compact mode (i.e. inside a container)
function show(io::IO, c::RGB)
    print(io, "($(c.r) $(c.g) $(c.b))")
end

# Human-readable show (more extended)
function show(io::IO, ::MIME"text/plain", c::RGB{T}) where {T}
    print(io, "RGB color with eltype $T\n", "R: $(c.r), G: $(c.g), B: $(c.b)")
end


# Write into a stream (for eltype(c) == Float32)
# Since we will work with PFM images, which uses 32-bit floating point
# values, we can directly write Float32 values.
write(io::IO, c::RGB{Float32}) = write(io, c...)

# Write into a stream (generic version): convert to float before writing
# Since we will work with PFM images, which uses 32-bit floating point
# values, we need to convert to Float32 before writing to stream.
function write(io::IO, c::RGB)
    @warn "Implicit conversion from $(eltype(c)) to Float32, since PFM images works with 32bit floating point values"
    write(io, convert.(Float32, c))
end

# Read a single instance of an RGB type from stream and return it
@inline function Base.read(io::IO, rgbT::Type{<:RGB})
    try
        _read(io, rgbT)
    catch e
        isa(e, ArgumentError) && throw(InvalidRgbStream("invalid input stream: corrupted binary data."))
        isa(e, EOFError) && throw(InvalidRgbStream("invalid input stream: not enough data to fill an instance of $rgbT."))
        rethrow(e)
    end
end


#########
# OTHER #
#########


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