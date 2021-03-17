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

# TODO implement iterate
# TODO implement broadcasting

# TODO implement tests