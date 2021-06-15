# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

###########
# Cylinder

"""
    Cylinder <: SimpleShape

A [`SimpleShape`](@ref) representing a cylinder of unitary height and diameter.

# Members

- `transformation::Transformation`: the `Transformation` associated with the cylinder.
- `material::Material`: the [`Material`](@ref) of the cylinder.
"""
Base.@kwdef struct Cylinder <: SimpleShape
    transformation::Transformation = Transformation()
    material::Material = Material()
end

@doc """
    Cylinder(transformation::Transformation, material::Material)

Constructor for a [`Cylinder`](@ref) instance.
""" Cylinder(::Transformation, ::Material)

@doc """
    Cylinder(transformation::Transformation = Transformation(),
           material::Material = Material())

Constructor for a [`Cylinder`](@ref) instance.
""" Cylinder(; ::Transformation, ::Material)

function get_t(::Type{Cylinder}, ray::Ray)
    sray = scaling(2) * ray
    ox, oy, oz = sray.origin.v
    dx, dy, dz = sray.dir

    # check if side is hit
    a = dx^2 + dy^2
    b = 2 * (ox * dx + oy * dy)
    c = ox^2 + oy^2 - 1
    Δ = b^2 - 4f0 * a * c
    if !(iszero(a) && iszero(b) && iszero(Δ)) && Δ >= 0
        sqrt_Δ = sqrt(Δ)
        t_1 = (-b - sqrt_Δ) / (2f0 * a)
        t_2 = (-b + sqrt_Δ) / (2f0 * a)
        # nearest point
        # @assert !isnan(t_1)
        # @assert !isnan(t_2)
        ray.tmin < t_1 < ray.tmax && abs(oz + t_1 * dz) <= 1f0 && return t_1
        ray.tmin < t_2 < ray.tmax && abs(oz + t_2 * dz) <= 1f0 && abs(oz) <= 1f0 && return t_2
    end

    # check if caps are hit
    tz1, tz2 = minmax(( 1f0 - oz) / dz, (-1f0 - oz) / dz)

    ray.tmin < tz1 < ray.tmax && (ox + tz1 * dx)^2 + (oy + tz1 * dy)^2 <= 1f0 && return tz1
    ray.tmin < tz2 < ray.tmax && (ox + tz2 * dx)^2 + (oy + tz2 * dy)^2 <= 1f0 && return tz2
    return Inf32
end

function get_all_ts(::Type{Cylinder}, ray::Ray)
    res = Vector{Float32}()
    sizehint!(res, 2)
    sray = scaling(2) * ray
    ox, oy, oz = sray.origin.v
    dx, dy, dz = sray.dir

    # check if side is hit
    a = dx^2 + dy^2
    b = 2 * (ox * dx + oy * dy)
    c = ox^2 + oy^2 - 1
    Δ = b^2 - 4f0 * a * c
    if !(iszero(a) && iszero(b) && iszero(Δ)) && Δ >= 0
        sqrt_Δ = sqrt(Δ)
        t_1 = (-b - sqrt_Δ) / (2f0 * a)
        t_2 = (-b + sqrt_Δ) / (2f0 * a)
        # nearest point
        # @assert !isnan(t_1)
        # @assert !isnan(t_2)
        abs(oz + t_1 * dz) <= 1f0 && push!(res, t_1)
        abs(oz + t_2 * dz) <= 1f0 && push!(res, t_2)
        length(res) == 2 && return res
    end

    # check if caps are hit
    tz1, tz2 = minmax(( 1f0 - oz) / dz, (-1f0 - oz) / dz)

    # ⪅(x::Number, y::Number) = x < y || x ≈ y
    # (ox + tz1 * dx)^2 + (oy + tz1 * dy)^2 ⪅ 1f0 && push!(res, tz1)
    # length(res) == 2 && return res
    # (ox + tz2 * dx)^2 + (oy + tz2 * dy)^2 ⪅ 1f0 && push!(res, tz2)
    # @assert (length(res) == 2 || length(res) == 0) "This cylinder does not have an entrance and an exit!\n\tres: $res\n\ttz1: $tz1\ttz2: $tz2"
    proj_height1, proj_height2 = (ox .+ (tz1, tz2) .* dx) .^ 2 .+ (oy .+ (tz1, tz2) .* dy) .^ 2 .|> x -> (x < 1f0 || x ≈ 1f0)
    if length(res) == 1
        if proj_height1
            push!(res, tz1)
        else
            @assert proj_height2
            push!(res, tz2)
        end
    elseif proj_height1 && proj_height2
        res = [tz1, tz2]
    end
    # @assert (length(res) == 2 || length(res) == 0) "This cylinder does not have an entrance and an exit!\n\tres: $res\n\ttz1: $tz1\ttz2: $tz2"
    return res
end

function get_normal(::Type{Cylinder}, point::Point, ray::Ray)
    z = point.v[3]
    # if it comes from the caps
    (abs(z) ≈ 0.5f0) && return -sign(z) * sign(ray.dir.z) * NORMAL_Z

    # if it comes from the side
    x, y = normalize(point.v[1:2])
    normal = Normal{true}(x, y, 0f0)
    (normal ⋅ ray.dir < 0) ? normal : -normal
end

function get_uv(::Type{Cylinder}, point::Point)
    x, y, z = point.v
    z ≈  0.5f0 && return Vec2D(3 - 2x, 3 - 2y) * 0.25f0
    z ≈ -0.5f0 && return Vec2D(3 - 2x, 1 + 2y) * 0.25f0
    (clamp(z + 0.5f0, 0, 1), (atan(y, x)/2π + 1) * 0.5f0)
end
