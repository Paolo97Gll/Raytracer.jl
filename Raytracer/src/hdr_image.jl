struct HdrImage{T}
    array_matrix::Matrix{T}
end

function HdrImage{T}(N::Integer,M::Integer) where {T}
    HdrImage{T}(zeros(RGB{T}, N, M))
end

function size(image::HdrImage)
    return size(image.array_matrix)
end

# TODO write(io::IO, image::HdrImage)

# TODO implement iterate
# TODO implement broadcasting

# TODO implement tests