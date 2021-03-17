function Base.zero(x::Type{RGB})
    T = eltype(x)
    RGB(zero(T), zero(T), zero(T))
end

struct HdrImage
    function HdrImage(N::Integer,M::Integer)
        new(zeros(RGB, N, M))
    end
    array_matrix::Matrix
end