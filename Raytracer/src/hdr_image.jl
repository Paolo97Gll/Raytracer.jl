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

Construct an `HdrImage` wrapping a zero-initialized matrix of size `(img_width, img_height)`.

# Examples
```jldoctest
julia> a = HdrImage(RGB{Float64}, 3, 2)
3x2 HdrImage{RGB{Float64}}
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
```
"""
@inline function HdrImage{T}(img_width::Integer, img_height::Integer) where {T}
    HdrImage{T}(zeros(T, img_width, img_height))
end

@inline function HdrImage(::Type{T}, img_width::Integer, img_height::Integer) where {T}
    HdrImage{T}(img_width, img_height)
end


"""
    HdrImage(img_width, img_height)

Construct an `HdrImage{RGB{Float32}}` wrapping a zero-initialized matrix of size `(img_width, img_height)`.

# Examples
```jldoctest
julia> a = HdrImage(3, 2)
3x2 HdrImage{RGB{Float32}}
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
```
"""
@inline function HdrImage(img_width::Integer, img_height::Integer)
    HdrImage{RGB{Float32}}(img_width, img_height)
end

"""
    HdrImage(arr, img_width, img_height)

Construct an `HdrImage{RGB{Float32}}` wrapping a matrix obtained from `reshape(arr, img_width, img_height)`.

# Examples
```jldoctest
julia> arr = [RGB( 1.,  2.,  3.), RGB( 4.,  5.,  6.), RGB( 7.,  8.,  9.), 
              RGB(10., 11., 12.), RGB(13., 14., 15.), RGB(16., 17., 18.)];

julia> a = HdrImage(arr, 3, 2)
3x2 HdrImage{RGB{Float64}}
 (1.0 2.0 3.0)  (10.0 11.0 12.0)
 (4.0 5.0 6.0)  (13.0 14.0 15.0)
 (7.0 8.0 9.0)  (16.0 17.0 18.0)
```
"""
function HdrImage(arr::AbstractArray{<:Any, 1}, im_width::Integer, im_height::Integer)
    HdrImage(reshape(arr, im_width, im_height))
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


function setindex!(image::HdrImage{T}, value::T, key::Integer) where {T}
    setindex!(image.pixel_matrix, value, key)
end

# TODO include type filter also here
setindex!(image::HdrImage, X, inds...) = setindex!(image.pixel_matrix, X, inds...)


function iterate(image::HdrImage{T}, state = 1) where {T}
    state > lastindex(image) ? nothing : (image[state], state + 1)
end


################
# BROADCASTING #
################


axes(image::HdrImage) = axes(image.pixel_matrix)
axes(image::HdrImage, d) = axes(image.pixel_matrix, d)

broadcastable(image::HdrImage) = image
broadcastable(::Type{<:HdrImage}) = HdrImage

BroadcastStyle(::Type{<:HdrImage}) = Style{HdrImage}()
BroadcastStyle(::Style{HdrImage}, ::BroadcastStyle) = Style{HdrImage}()

@inline function copy(bc::Broadcasted{Style{HdrImage}})
    ElType = combine_eltypes(bc.f, bc.args)
    return HdrImage{ElType}(reshape(collect(convert(Broadcasted{Nothing}, bc)), axes(bc)))
end


######
# IO #
######


# needed for show
size(image::HdrImage) = size(image.pixel_matrix)


# Show in compact mode (i.e. inside a container)
function show(io::IO, image::HdrImage{T}) where {T}
    print_matrix(io, image.pixel_matrix)
end

# Human-readable show (more extended)
function show(io::IO, ::MIME"text/plain", image::HdrImage{T}) where {T}
    println(io, "$(join(map(string, size(image)), "x")) $(typeof(image))")
    print_matrix(io, image.pixel_matrix)
end


# write on stream in PFM format
# need HdrImage broadcasting
function write(io::IO, image::HdrImage)
    write(io, transcode(UInt8, "PF\n$(join(size(image)," "))\n$(little_endian ? -1. : 1.)\n"),
        (c for c ∈ image[:, end:-1:begin])...)
end


# #########
# # OTHER #
# #########


eltype(::HdrImage{T}) where {T} = T

fill!(image::HdrImage, x) = HdrImage(fill!(image.pixel_matrix, x))