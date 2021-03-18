struct HdrImage{T}
    pixel_matrix::Matrix{T}
end

function HdrImage{T}(N::Integer,M::Integer) where {T}
    HdrImage{T}(zeros(RGB{T}, N, M))
end

# TODO Samuele: write(io::IO, image::HdrImage)

############
# ITERATOR #
############

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

#########
# OTHER #
#########

function size(image::HdrImage)
    return size(image.pixel_matrix)
end

function Base.show(io::IO, ::MIME"text/plain", image::HdrImage{T}) where {T}
    println(io, "$(join(map(string, size(image)), "x")) $(typeof(image))")
    Base.print_matrix(io, image.pixel_matrix)
end