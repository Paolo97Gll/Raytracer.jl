struct HdrImage{T}
    pixel_matrix::Matrix{T}
end

function HdrImage{T}(N::Integer,M::Integer) where {T}
    HdrImage{T}(zeros(RGB{T}, N, M))
end

function size(image::HdrImage)
    return size(image.pixel_matrix)
end

# TODO write(io::IO, image::HdrImage)

# implementing an iterator over RGB
eltype(::HdrImage{T}) where {T} = T

length(image::HdrImage) = length(image.pixel_matrix)

firstindex(image::HdrImage) = firstindex(image.pixel_matrix)

lastindex(image::HdrImage) = lastindex(image.pixel_matrix)

getindex(image::HdrImage, inds...) = getindex(image.pixel_matrix, inds...)

setindex!(image::HdrImage, value, key) = setindex!(image.pixel_matrix, value, key)
setindex!(image::HdrImage, X, inds...) = setindex!(image.pixel_matrix, X, inds...)

function iterate(image::HdrImage{T}, state = 1) where {T}
    state > lastindex(image) ? nothing : (image[state], state + 1)
end

# TODO implement broadcasting

axes(image::HdrImage) = axes(image.pixel_matrix)

Broadcast.BroadcastStyle(::Type{<:HdrImage{T}}) where {T} = Broadcast.Style{HdrImage{T}}
Broadcast.BroadcastStyle(::Broadcast.Style{HdrImage{T}}, ::Broadcast.BroadcastStyle) where {T} = Broadcast.Style{HdrImage{T}}()

function similar(bc::Broadcast.Broadcasted{Broadcast.Style{HdrImage{T}}}, ::Type{T}) where {T}
    HdrImage{T}(similar(Matrix{T}, axes(bc)))
end

# TODO implement tests