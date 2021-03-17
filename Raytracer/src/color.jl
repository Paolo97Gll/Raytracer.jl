##############
# OPERATIONS #
##############


"""Dispatch of elementwise addition between two RGB type instances"""
(+)(c1::RGB{T}, c2::RGB{T}) where {T} = RGB{T}(c1.r + c2.r, c1.g + c2.g, c1.b + c2.b)

"""Dispatch of elementwise subtraction di between two RGB type instances"""
(-)(c1::RGB{T}, c2::RGB{T}) where {T} = RGB{T}(c1.r - c2.r, c1.g - c2.g, c1.b - c2.b)

"""Dispatch of scalar multiplication for a RGB type instance"""
(*)(scalar::Number, c::RGB{T}) where {T} = RGB{T}(scalar * c.r, scalar * c.g, scalar * c.b)

"""Mirrored version of scalar multiplication for a RGB type instance"""
(*)(c::RGB{T}, scalar::Number) where {T} = scalar * c

"""Dispatch of elementwise multiplication between two RGB type instances"""
(*)(c1::RGB{T}, c2::RGB{T}) where {T} = RGB{T}(c1.r * c2.r, c1.g * c2.g, c1.b * c2.b)

"""Dispatch of elementwise ≈ operator between two RGB type instances"""
(≈)(c1::RGB{T}, c2::RGB{T}) where {T} = c1.r ≈ c2.r && 
                                        c1.g ≈ c2.g &&
                                        c1.b ≈ c2.b


############
# ITERATOR #
############


# implementing an iterator over RGB
eltype(::RGB{T}) where {T} = T

length(c::RGB{T}) where {T} = 3

firstindex(c::RGB{T}) where {T} = 1

function lastindex(c::RGB{T}) where {T}
    length(c)
end

function getindex(c::RGB{T}, i::Integer) where {T}
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
function getindex(c::RGB{T}, i::CartesianIndex{1}) where {T}
    getindex(c, Tuple(i)[1])
end

function iterate(c::RGB{T}, state = 1) where {T}
    state > 3 ? nothing : (c[state], state +1)
end


################
# BROADCASTING #
################


# implementing broadcasting
# broadcasting a function `f` on a series of arguments `xs` (ie. `f.(xs...)`) is equivalent to writing
# the following `materialize(broadcasted(combine_styles(map(broadcastable, xs)), f, xs...))`
# let's analyze what each of these functions does and why each of the following methods is needed

# let's start with broadcastable: broadcasting maps its arguments so that each argument is transformed 
# into a type supporting indexing and the method `axes`, and thus being able to be converted into an
# array-like type. We'll trick the broadcasting process into thinking this is the case for `RGB` so that
# `broadcastable` will return its argument when it is applied to an `RGB`

axes(::RGB{T}) where {T} = (OneTo(3),) 

Broadcast.broadcastable(c::RGB{T}) where {T} = c 
Broadcast.broadcastable(::Type{RGB}) = RGB # broadcastable is also applied to types

# then the result of the previous mapping is passed onto the function `combine_styles`, which
# relies on calls to the constructor of `BroadcastStyle`. We need to create a `BroadcastStyle` 
# exclusive to `RGB` so that we can then specialize other methods that are fed `BroadcastStyle`s
struct RGBBroadcastStyle <: Broadcast.BroadcastStyle end
# then we specialize the constructor from instances of `RGB`
Broadcast.BroadcastStyle(::Type{<:RGB}) = RGBBroadcastStyle()
# and the constructor that combines the `RGBBroadcastStyle` with any other `BroadcastStyle`
# we want our style to have precedence over any other so that if an `RGB` type is present among
# the arguments of broadcasting the result will be of type `RGB`
Broadcast.BroadcastStyle(::RGBBroadcastStyle, ::Broadcast.BroadcastStyle) = RGBBroadcastStyle()

# the call to `materialize` returns a call to `copy`, which by default is specialized for array-like types
# we then have to implement a method that treats any `Broadcasted` type with our custom `RGBBroadcastStyle`
# in an appropriate way. 
@inline function Broadcast.copy(bc::Broadcast.Broadcasted{RGBBroadcastStyle})
    # the call to `convert` to a `Broadcasted` type of style `Nothing` computes
    # the result of the broadcasting and stores it into an array. splatting this
    # array into an `RGB` constructor gives us the desired result
    return RGB(convert(Broadcast.Broadcasted{Nothing}, bc)...)
end


#########
# OTHER #
#########


function zero(x::Type{RGB})
    z = zero(eltype(x))
    RGB(z, z, z)
end