# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   geometry.jl
# description:
#   Implementation of the geometry required for the generation
#   and manipulation of a 3D scene.


#####################################################################


for V ∈ (:Vec, :Normal)
    quote
        struct $V{T} <: FieldVector{3, T}
            x::T
            y::T
            z::T
        end

        # Show in compact mode (i.e. inside a container)
        function show(io::IO, a::$V)
            print(io, typeof(a), "(", join((string(el) for el ∈ a), ", "), ")")
        end

        # Human-readable show (more extended)
        function show(io::IO, ::MIME"text/plain", a::$V)
            print(io, $V, " with eltype $(eltype(a))\n", join(("$label = $el" for (label, el) ∈ zip((:x, :y, :z), a)), ", "))
        end

        norm²(v::$V) = sum(el -> el^2, v)
    end |> eval
end


#####################################################################


struct Point{T}
    v::SVector{3, T}
end

eltype(::Point{T}) where {T} = T
eltype(::Type{Point{T}}) where {T} = T

# Convenience constructor
Point(p::AbstractArray{T}) where {T} = Point(SVector{size(p)...}(p))

# Show in compact mode (i.e. inside a container)
function show(io::IO, a::Point)
    print(io, typeof(a), "(", join((string(el) for el ∈ a.v), ", "), ")")
end

# Human-readable show (more extended)
function show(io::IO, ::MIME"text/plain", a::Point)
    print(io, Point, " with eltype $(eltype(a))\n", join(("$label = $el" for (label, el) ∈ zip((:x, :y, :z), a.v)), ", "))
end

(≈)(p1::Point, p2::Point) = p1.v ≈ p2.v
(-)(p1::Point, p2::Point) = Vec(p1.v - p2.v)
(+)(p::Point, v::Vec) = Point(p.v + v)
(-)(p::Point, v::Vec) = Point(p.v - v)
(*)(p::Point, s...) = (*)(p.v, s...) |> Point


#####################################################################


struct Transformation{V}
    m::AbstractMatrix{V}
    invm::AbstractMatrix{V} 

    function Transformation{T}(m::AbstractMatrix{T} = Diagonal(ones(T,4)), invm::AbstractMatrix{T} = (m\I(4))) where {T}
        @assert(size(m)==size(invm)==(4,4))
        new{T}(m, invm)
    end
end

Transformation(m::AbstractMatrix{T}) where {T} = Transformation{T}(m)
Transformation(m::AbstractMatrix{T}, invm::AbstractMatrix{T}) where {T} = (@assert(m*invm ≈ I(4)); Transformation{T}(m, invm))
Transformation(m::Matrix{T}, invm::Matrix{T}) where {T} = Transformation(SMatrix{4, 4, T}(m), SMatrix{4, 4, T}(invm))

eltype(::Transformation{T}) where {T} = T
eltype(::Type{Transformation{T}}) where {T} = T

function show(io::IO, ::MIME"text/plain", a::Transformation)
    println(io, "4x4 $(typeof(a)):")
    println(io, "Matrix:");
    print_matrix(io, a.m);
    println(io, "\nInverse matrix:");
    print_matrix(io, a.invm);
end

isconsistent(t::Transformation) = (t.m * t.invm) ≈ I(4)

# TODO implement all the other functions and operations
