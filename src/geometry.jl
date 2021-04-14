# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   geometry.jl
# description:
#   Implementation of the geometry required for the generation
#   and manipulation of a 3D scene.


abstract type RaytracerGeometry end


#####################################################################


abstract type VectorSpace{T<:Real} <: RaytracerGeometry end


eltype(::VectorSpace{T}) where {T} = T
eltype(::Type{VectorSpace{T}}) where {T} = T


# Show in compact mode (i.e. inside a container)
function show(io::IO, a::VectorSpace)
    print(io, "$(typeof(a))($(a.x) $(a.y) $(a.z))")
end

# Human-readable show (more extended)
function show(io::IO, ::MIME"text/plain", a::VectorSpace{T}) where {T}
    print(io, "$(typeof(a)) with eltype $T\n", "x = $(a.x), y = $(a.y), z = $(a.z)")
end


#####################################################################


for T ∈ (:Vec, :Point)
    quote
        struct $T{V} <: VectorSpace{V}
            x::V
            y::V
            z::V
        end        
    end |> eval
end


for T ∈ (:Vec, :Point)
    quote
        function (≈)(a1::$T, a2::$T)
            Base.:≈(a1.x, a2.x) &&
            Base.:≈(a1.y, a2.y) &&
            Base.:≈(a1.z, a2.z)
        end
    end |> eval
end


(+)(p::V, v::Vec) where {V <: Union{Point, Vec}} = eval(nameof(V))(p.x + v.x, p.y + v.y, p.z + v.z)
(-)(p::V, v::Vec) where {V <: Union{Point, Vec}} = eval(nameof(V))(p.x - v.x, p.y - v.y, p.z - v.z)
(-)(p1::Point, p2::Point) = Vec(p1.x - p2.x, p1.y - p2.y, p1.z - p2.z)
