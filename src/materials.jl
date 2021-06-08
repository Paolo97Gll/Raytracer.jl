# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Implementation of Pigments and BRDFs
# TODO write docstrings


#####################################################################


abstract type Pigment end

function (p::Pigment)(uv::Vec2D)
    p(uv...)
end


#################
# UniformPigment


Base.@kwdef struct UniformPigment <: Pigment
    color::RGB{Float32} = WHITE
end

(up::UniformPigment)(::Float32, ::Float32) = up.color


###################
# CheckeredPigment


struct CheckeredPigment{N} <: Pigment
    color_on::RGB{Float32}
    color_off::RGB{Float32}

    function CheckeredPigment{N}(color_on::RGB{Float32}, color_off::RGB{Float32}) where {N}
        @assert isa(N, Integer)
        new{N}(color_on, color_off)
    end
end

function CheckeredPigment(color_on::RGB{Float32} = WHITE, color_off::RGB{Float32} = BLACK)
    CheckeredPigment{2}(color_on, color_off)
end

function CheckeredPigment{N}(; color_on::RGB{Float32} = WHITE, color_off::RGB{Float32} = BLACK) where {N}
    CheckeredPigment{N}(color_on, color_off)
end

function (cp::CheckeredPigment{N})(u::Float32, v::Float32) where {N}
    ceil(u*N)%2 == ceil(v*N)%2 ? cp.color_on : cp.color_off
end


###############
# ImagePigment


struct ImagePigment <: Pigment
    image::HdrImage
end

function (ip::ImagePigment)(u::Float32, v::Float32)
    size_row, size_col = size(ip.image)
    f(x) = iszero(x) ? x + 1 : x
    row = u * size_row |> ceil |> Int |> f
    col = v * size_col |> ceil |> Int |> f
    ip.image[row, col]
end


#####################################################################


abstract type BRDF end


##############
# DiffuseBRDF


Base.@kwdef struct DiffuseBRDF <: BRDF
    pigment::Pigment = UniformPigment()
    reflectance::Float32 = 1f0
end

function at(brdf::DiffuseBRDF, normal::Normal, in_dir::Vec, out_dir::Vec, uv::Vec2D)
    brdf.pigment(uv) * (brdf.reflectance / π)
end

function scatter_ray(::DiffuseBRDF, pcg::PCG, incoming_dir::Vec,
                     interaction_point::Point, normal::Normal, depth::Int)
    e1, e2, e3 = create_onb_from_z(normal)
    cos_θ_sq = rand(pcg, Float32)
    cos_θ = sqrt(cos_θ_sq)
    φ = 2f0 * π * rand(pcg, Float32)

    Ray(
        interaction_point,
        e1 * cos(φ) * cos_θ + e2 * sin(φ) * cos_θ + e3 * sqrt(1f0 - cos_θ_sq),
        1.0f-3,
        Inf32,
        depth
    )
end


###############
# SpecularBRDF


Base.@kwdef struct SpecularBRDF <: BRDF
    pigment::Pigment = UniformPigment()
    threshold_angle_rad::Float32 = π / 1800f0
end

function at(brdf::SpecularBRDF, normal::Normal, in_dir::Vec, out_dir::Vec, uv::Vec2D)
    θ_in = normalized_dot(normal, in_dir) |> acos
    θ_out = normalized_dot(normal, out_dir) |> acos
    abs(θ_in - θ_out) < brdf.threshold_angle_rad < brdf.threshold_angle_rad ? brdf.pigment(uv) : BLACK
end

function scatter_ray(::SpecularBRDF, pcg::PCG, incoming_dir::Vec,
                     interaction_point::Point, normal::Normal, depth::Int)
    ray_dir = normalize(incoming_dir)
    normal = normalize(normal)

    Ray(interaction_point,
        ray_dir - normal * 2f0 * (normal ⋅ ray_dir),
        1f-3,
        Inf32,
        depth)
end


#####################################################################


Base.@kwdef struct Material
    brdf::BRDF = DiffuseBRDF()
    emitted_radiance::Pigment = UniformPigment(BLACK)
end
