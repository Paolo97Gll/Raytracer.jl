
# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

#######
# Cone

"""
    Cone{radius_ratio} <: SimpleShape

A [`SimpleShape`](@ref) representing a truncated cone of unitary height, unitary base radius, and `radius_ratio` upper circle diameter.

The `radius_ratio` is part of the type signature so that a unitary shape can be defined for the type. The origin point is located at the center of the circular base.

# Members

- `transformation::Transformation`: the `Transformation` associated with the cylinder.
- `material::Material`: the [`Material`](@ref) of the cylinder.
"""
struct Cone{radius_ratio} <: SimpleShape
    transformation::Transformation
    material::Material
	function Cone(transformation::Transformation, material::Material, radius_ratio::Float32)
		abs(radius_ratio) <= 1f0 || throw(ArgumentError("the `radius_ratio` must have an absolute value less than 1: got $radius_ratio"))
		new{radius_ratio}(transformation, material)
	end
end

function Cone(; transformation::Transformation = Transformation(), material::Material = Material(), radius_ratio::Float32 = 0f0)
	Cone(transformation, material, radius_ratio)
end

@doc """
    Cone(transformation::Transformation, material::Material)

Constructor for a [`Cone`](@ref) instance.
""" Cone(::Transformation, ::Material)

@doc """
    Cone(transformation::Transformation = Transformation(),
           material::Material = Material())

Constructor for a [`Cone`](@ref) instance.
""" Cone(; ::Transformation, ::Material)

function get_t(::Type{Cone{RR}}, ray::Ray) where {RR}
	res = filter(t -> ray.tmin < t < ray.tmax, get_all_ts(Cone{RR}, ray))
	isempty(res) && return Inf32
	minimum(res)
end

function get_all_ts(::Type{Cone{RR}}, ray::Ray) where {RR}
    res = Vector{Float32}()
	â  = Normal{true}(0, 0, 1f0)
	dx, dy, dz = s⃗ = ray.dir
	ox, oy, oz = e⃗ = convert(Vec, ray.origin)
	R₀ = 1f0
	R₁ = RR - 1f0
	Z₀ = e⃗ ⋅ â
	Z₁ = s⃗ ⋅ â

	P⃗  = s⃗ - Z₁ * â
	Q⃗  = e⃗ - Z₀ * â

	B₂ = norm²(P⃗) - R₁^2 * Z₁^2
	B₁ = Z₁ * R₁ * (R₁ * Z₀ + R₀) - P⃗ ⋅ Q⃗
	B₀ = norm²(Q⃗) - (R₁ * Z₀ + R₀)^2

	if B₂ ≈ 0f0 && !(B₁ ≈ 0f0)
		t = B₀/2B₁
		0 <= Z₁ * t + Z₀ <= 1 && push!(res, t)
	elseif (Δ = B₁^2 - B₀ * B₂) >= 0f0
		t1 = (B₁ + sqrt(Δ))/B₂
		t2 = (B₁ - sqrt(Δ))/B₂
		0 <= Z₁ * t1 + Z₀ <= 1 && push!(res, t1)
		0 <= Z₁ * t2 + Z₀ <= 1 && push!(res, t2)
	end

    # check if caps are hit
    tz1, tz2 = (( 1f0 - oz) / dz, - oz / dz)

	if !iseven(length(res))
		(ox + tz1 * dx)^2 + (oy + tz1 * dy)^2 <= RR^2 ? push!(res, tz1) : push!(res, tz2)
		@assert (check = (ox + tz2 * dx)^2 + (oy + tz2 * dy)^2) <=  1f0 "it was actually $check !<= 1f0"
	elseif (ox + tz2 * dx)^2 + (oy + tz2 * dy)^2 <=  1f0
		append!(res, [tz1, tz2])
	end
	return res
end

function get_normal(::Type{Cone{RR}}, point::Point, ray::Ray) where {RR}
    z = ray.origin[3]
	abs_z = abs(z)
    # if it comes from the upper cap
	# or if it comes from the base
    (abs_z ≈ 1f0 || abs_z ≈ 0f0) && return -sign(z) * sign(ray.dir.z) * NORMAL_Z

    # if it comes from the side
	z = 1/(1f0 - RR) * sign(1/(1 - RR) - point[3])
    x, y = point.v[1:2]
	normal = Normal(x, y, z) |> normalize
    (normal ⋅ ray.dir < 0) ? normal : -normal
end

function get_uv(::Type{<:Cone}, point::Point)
    x, y, z = point.v
    z ≈ 0f0 && return Vec2D(x, (1 + y/2) * 0.25f0)
    return Vec2D(x, (3 + y/2) * 0.25f0)
end
