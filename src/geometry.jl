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


for T ∈ (:Vec, :Point)
    quote
        struct $T{V} <: VectorSpace{V}
            v::SVector{3, V}
        end

        # Convenience constructor
        $T(v::AbstractArray{T}) where {T} = $T(SVector{size(v)...}(v))

        # Human-readable show (more extended)
        function show(io::IO, ::MIME"text/plain", a::$T)
            print(io, $T, " with eltype $(eltype(a))\n", join(("$label = $el" for (label, el) ∈ zip((:x, :y, :z), a.v)), ", "))
        end

        # Show in compact mode (i.e. inside a container)
        function show(io::IO, a::$T)
            print(io, typeof(a), "(", join((string(el) for el ∈ a.v), ", "), ")")
        end
    end |> eval
end

@delegate_onefield(Vec, v, [norm])
@delegate_onefield_astype(Vec, v, [normalize, (*)])
norm²(v::Vec) = sum(el -> el^2, v.v)
@delegate_onefield_twovars(Vec, v, [(≈), (⋅)])
@delegate_onefield_twovars_astype(Vec, v, [(+), (-), (×)])
(*)(s, v::Vec) = v * s

(-)(p1::Point, p2::Point) = Vec(p1.v - p2.v)
(+)(p::Point, v::Vec) = Point(p.v + v.v)
(-)(p::Point, v::Vec) = Point(p.v - v.v)