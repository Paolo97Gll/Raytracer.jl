# This file implement the structure HdrImage, which is used to represent an HDR image
#
# Current implementation info:
# - ITERATIONS. Since an HdrImage type is a wrapper struct around a Matrix, iterating
#   on an image means iterating on the underlying Matrix, and in this way we'll implement.
# - BROADCASTING. Same consideration made for the iterations.
# - IO. Utilities for various IO operations, such as printing or writing into
#   a stream.
# - OTHER. Other usefull utilities.
#
# More informations are reported above the single implementation.


##################
# MAIN STRUCTURE #
##################


"""
    HdrImage{T}

Class representing an HDR image in a `Matrix` of eltype `T`.
"""
struct HdrImage{T}
    pixel_matrix::Matrix{T}
end

"""
    HdrImage{T}(img_width, img_height)
    HdrImage(::Type{T}, img_width, img_height)

Construct an `HdrImage` wrapping a matrix of size `(img_width, img_height)` filled with `zero(T)`s.

# Examples
```jldoctest
julia> a = HdrImage(RGB{Float64}, 3, 2)
2x3 HdrImage{RGB{Float64}}
 (0.0 0.0 0.0)  (0.0 0.0 0.0)  (0.0 0.0 0.0)
 (0.0 0.0 0.0)  (0.0 0.0 0.0)  (0.0 0.0 0.0)
```
"""
@inline function HdrImage{T}(img_width::Integer, img_height::Integer) where {T<:RGB}
    HdrImage{T}(zeros(T, img_width, img_height))
end
@inline function HdrImage(::Type{T}, img_width::Integer, img_height::Integer) where {T}
    HdrImage{T}(img_width, img_height)
end

"""
    HdrImage(img_width, img_height)

Construct an `HdrImage{RGB{Float32}}` wrapping a matrix of size `(img_width, img_height)`.

# Examples
```jldoctest
julia> a = HdrImage(3, 2)
2x3 HdrImage{RGB{Float32}}
 (0.0 0.0 0.0)  (0.0 0.0 0.0)  (0.0 0.0 0.0)
 (0.0 0.0 0.0)  (0.0 0.0 0.0)  (0.0 0.0 0.0)
```
"""
@inline function HdrImage(img_width::Integer, img_height::Integer)
    HdrImage{RGB{Float32}}(img_width, img_height)
end


##############
# ITERATIONS #
##############


length(image::HdrImage) = length(image.pixel_matrix)

firstindex(image::HdrImage) = firstindex(image.pixel_matrix)
firstindex(image::HdrImage, d) = firstindex(image.pixel_matrix, d)

lastindex(image::HdrImage) = lastindex(image.pixel_matrix)
lastindex(image::HdrImage, d) = lastindex(image.pixel_matrix, d)

getindex(image::HdrImage, inds...) = getindex(image.pixel_matrix, inds...)

setindex!(image::HdrImage, value, key) = setindex!(image.pixel_matrix, value, key)
setindex!(image::HdrImage, X, inds...) = setindex!(image.pixel_matrix, X, inds...)

function iterate(image::HdrImage{T}, state = 1) where {T}
    state > lastindex(image) ? nothing : (image[state], state + 1)
end


################
# BROADCASTING #
################


axes(image::HdrImage) = axes(image.pixel_matrix)
axes(image::HdrImage, d) = axes(image.pixel_matrix, d)

BroadcastStyle(::Type{<:HdrImage{T}}) where {T} = Style{HdrImage{T}}
BroadcastStyle(::Style{HdrImage{T}}, ::BroadcastStyle) where {T} = Style{HdrImage{T}}()

function similar(bc::Broadcasted{Style{HdrImage{T}}}, ::Type{T}) where {T}
    HdrImage{T}(similar(Matrix{T}, axes(bc)))
end


######
# IO #
######


function Base.show(io::IO, ::MIME"text/plain", image::HdrImage{T}) where {T}
    println(io, "$(join(map(string, size(image)), "x")) $(typeof(image))")
    Base.print_matrix(io, image.pixel_matrix)
end

function Base.write(io::IO, image::HdrImage)
    write(io, transcode(UInt8, "PF\n$(join(size(image)," "))\n$(little_endian ? -1. : 1.)\n"),
     (c for c ∈ image[end:-1:begin, :])...)
end


#########
# OTHER #
#########


eltype(::HdrImage{T}) where {T} = T

function size(image::HdrImage)
    return size(image.pixel_matrix)
end

function fill!(image::HdrImage, x)
    HdrImage(fill!(image.pixel_matrix, x))
end