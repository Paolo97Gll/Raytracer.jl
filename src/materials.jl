abstract type Pigment end

function (p::Pigment)(uv::Vec2D)
    p(uv...)
end

Base.@kwdef struct UniformPigment{T <: RGB} <: Pigment
    color::T = one(T)
end

function (up::UniformPigment)(::Real, ::Real)
    up.color
end

struct CheckeredPigment{N, T <: RGB} <: Pigment
    color_on::T
    color_off::T
    function CheckeredPigment{N, T}(color_on::T = one(T), color_off::T = zero(T)) where {N, T}
        @assert isa(N, Integer)
        new{N,T}(color_on, color_off)
    end
end

function CheckeredPigment{N}(; color_on::T = one(T), color_off::T = zero(T)) where {N,T <: RGB}
    CheckeredPigment{N, T}(color_on, color_off)
end

function CheckeredPigment{N}(color_on::T, color_off::T) where {N,T <: RGB}
    CheckeredPigment{N, T}(color_on, color_off)
end

function CheckeredPigment(color_on::RGB, color_off::RGB)
    CheckeredPigment{2}(color_on, color_off)
end

function (cp::CheckeredPigment{N})(u::Real, v::Real) where {N}
    ceil(u*N)%2 == ceil(v*N)%2 ? cp.color_on : cp.color_off
end

struct ImagePigment{T <: HdrImage} <: Pigment
    image::T
end

function (ip::ImagePigment)(u::Real, v::Real)
    row, col = (u, v) .* size(ip.image) .|> ceil .|> Int .|> (x -> x == 0 ? x + 1 : x)
    ip.image[row, col]
end

abstract type BRDF end

Base.@kwdef struct DiffuseBRDF{T <: AbstractFloat} <: BRDF
    pigment::Pigment = UniformPigment{RGB{T}}()
    reflectance::T = one(T)
end

function at(brdf::DiffuseBRDF, #=normal=#::Normal, #=in_dir=#::Vec, #=out_dir=#::Vec, uv::Vec2D)
    brdf.pigment(uv) * brdf.reflectance/π
end

function scatter_ray(::DiffuseBRDF, pcg::PCG, #=incoming_dir=#::Vec,
                     interaction_point::Point, normal::Normal, depth::Integer)
    e1, e2, e3 = create_onb_from_z(normal)
    cos_theta_sq = rand(pcg, Float32)
    cos_theta, sin_theta = sqrt(cos_theta_sq), sqrt(1.0 - cos_theta_sq)
    phi = 2.0 * π * rand(pcg, Float32)

    Ray(interaction_point,
        e1 * cos(phi) * cos_theta + e2 * sin(phi) * cos_theta + e3 * sin_theta,
        1.0e-3,
        Inf,
        depth)
end

Base.@kwdef struct SpecularBRDF{T <: AbstractFloat} <: BRDF
    pigment::Pigment = UniformPigment{RGB{T}}()
    threshold_angle_rad::T
end

function at(brdf::SpecularBRDF{T}, normal::Normal, in_dir::Vec, out_dir::Vec, uv::Vec2D) where {T}
    δθ = -((Ref(n) .⋅ (v1, v2) .|> acos)...)
    δθ < brdf.threshold_angle_rad ? brdf.pigment(uv) : zero(RGB{T})
end

function scatter_ray(::SpecularBRDF, pcg::PCG, incoming_dir::Vec,
                     interaction_point::Point, normal::Normal, depth::Integer)
    ray_dir = normalize(incoming_dir)
    normal  = normalize(normal)

    Ray(interaction_point,
        ray_dir - normal * 2 * (normal ⋅ ray_dir),
        1e-3,
        inf,
        depth)
end

Base.@kwdef struct Material
    brdf::BRDF = DiffuseBRDF{Float64}()
    emitted_radiance::Pigment = UniformPigment(zero(RGB{Float64})) 
end