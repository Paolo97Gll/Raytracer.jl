# This file implement the structure HdrImage, which is used to represent an
# HDR image
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


##################
# MAIN STRUCTURE #
##################


struct HdrImage{T}
    pixel_matrix::Matrix{T}
end

@inline function HdrImage{T}(width::Integer, height::Integer) where {T}
    HdrImage{T}(zeros(T, height, width))
end

@inline function HdrImage(::Type{T}, width::Integer, height::Integer) where {T}
    HdrImage{T}(width, height)
end

@inline function HdrImage(width::Integer, height::Integer)
    HdrImage{RGB{Float32}}(width, height)
end


##############
# ITERATIONS #
##############


eltype(::HdrImage{T}) where {T} = T

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


function size(image::HdrImage)
    return size(image.pixel_matrix)
end

function fill!(image::HdrImage, x)
    fill!(image.pixel_matrix, x)
end