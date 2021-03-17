struct HdrImage{T}
    function HdrImage{T}(N::Integer,M::Integer) where {T}
        new{T}(zeros(RGB{T}, N, M))
    end
    array_matrix::Matrix{T}
end