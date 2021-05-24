abstract type Pigment end

function (p::Pigment)(uv::Vec2D)
    p(uv...)
end

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
    row, col = (u, v) .* size(ip.image) .|> ceil .|> Int .|> (x -> x == 0 ? x + 1 : x)
    ip.image[row, col]
end

abstract type BRDF end

Base.@kwdef struct DiffuseBRDF{T <: AbstractFloat}
    pigment::Pigment = UniformPigment()
    reflectance::T = one(T)
end

function at(brdf::DiffuseBRDF, #=normal=#::Normal, #=in_dir=#::Vec, #=out_dir=#::Vec, uv::Vec2D)
    brdf.pigment(uv) * brdf.reflectance/π
end