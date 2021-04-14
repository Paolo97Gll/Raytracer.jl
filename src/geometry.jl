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
            v::SVector{3, V}
        end        

        # Convenience constructor
        $T(v::AbstractArray{T}) where {T} = $T(SVector{size(v)...}(v))
        
        # TODO Paolo: implement these
        # (+)(p::$T, v::Vec) = $T(p.v + v.v)
        # (-)(p::$T, v::Vec) = $T(p.v - v.v)

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


# TODO Paolo: implement these
# (-)(p1::Point, p2::Point) = Vec(p1.v - p2.v)