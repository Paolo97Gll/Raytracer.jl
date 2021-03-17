struct HdrImage{T}
    function HdrImage{T}(N::Integer,M::Integer) where {T}
        new{T}(zeros(RGB{T}, N, M))
    end
    array_matrix::Matrix{T}
end

function size(image::HdrImage)
    return size(image.array_matrix)
end

# TODO write(io::IO, image::HdrImage)

# TODO implement iterate
# TODO implement broadcasting