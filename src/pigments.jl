abstract type Pigment end

Base.@kwdef struct UniformPigment{T <: RGB}
    color::T = one(T)
end

function (up::UniformPigment)(::Real, ::Real)
    up.color
end

Base.@kwdef struct CheckeredPigment{N, T <: RGB}
    color_on::T  = one(T)
    color_off::T = zero(T)
end

function CheckeredPigment(color_on::RGB, color_off::RGB)
    CheckeredPigment{2}(color_on, color_off)
end

function (cp::CheckeredPigment{N})(u::Real, v::Real) where {N}
    ceil(u*N)%2 == ceil(v*N)%2 ? cp.color_on : cp.color_off
end

struct ImagePigment{T <: HdrImage} 
    image::T
end

function (ip::ImagePigment)(u::Real, v::Real)
    row, col = (u, v) .* size(ip.image) .|> ceil .|> Int
    ip.image[row, col]
end