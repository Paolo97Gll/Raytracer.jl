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

Point(x::Real, y::Real, z::Real) = Point(SVector(x,y,z))
function Point(p::AbstractVector)
    size(p) == (3,) || throw(ArgumentError("argument 'p' has size = $(size(p)) but 'Point' requires an argument of size = (3,)"))

    Point(SVector{3}(p))
end

eltype(::Point{T}) where {T} = T
eltype(::Type{Point{T}}) where {T} = T

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
    invm::AbstractMatrix 

    function Transformation{T}(m::AbstractMatrix{T} = Diagonal(ones(T,4)), invm::AbstractMatrix = (m\I(4))) where {T}
        @assert(size(m)==size(invm)==(4,4))
        new{T}(m, invm)
    end
end

Transformation(m::AbstractMatrix{T}) where {T} = Transformation{T}(m)
Transformation(m::AbstractMatrix{T}, invm::AbstractMatrix) where {T} = (@assert(m*invm ≈ I(4)); Transformation{T}(m, invm))
Transformation(m::Matrix{T}, invm::Matrix{T2}) where {T, T2} = Transformation(SMatrix{4, 4, T}(m), SMatrix{4, 4, T2}(invm))

eltype(::Transformation{T}) where {T} = T
eltype(::Type{Transformation{T}}) where {T} = T

function show(io::IO, ::MIME"text/plain", t::Transformation)
    println(io, "4x4 $(typeof(t)):")
    println(io, "Matrix of type ", typeof(t.m), ":");
    print_matrix(io, t.m);
    println(io, "\nInverse matrix of type ", typeof(t.invm), ":");
    print_matrix(io, t.invm);
end

isconsistent(t::Transformation) = (t.m * t.invm) ≈ I(4)


(*)(t1::Transformation, t2::Transformation) = Transformation(t1.m * t2.m, t2.invm * t1.invm)
(*)(t ::Transformation, v ::Vec)            = @view(t.m[1:3,1:3]) * v
(*)(t ::Transformation, n ::Normal)         = transpose(@view(t.invm[1:3,1:3])) * n
(*)(t ::Transformation, p ::Point)          = t.m * SVector(p.v..., one(eltype(p))) 

inverse(t::Transformation) = Transformation(t.invm, t.m)

let rotation_matrices = Dict(
        :X => θ -> @SMatrix([   1       0      0    0;
                                0     cos(θ) sin(θ) 0;
                                0    -sin(θ) cos(θ) 0;
                                0       0      0    1]),
        :Y => θ -> @SMatrix([ cos(θ)    0   -sin(θ) 0;
                                0       1      0    0;
                              sin(θ)    0    cos(θ) 0;
                                0       0      0    1]),
        :Z => θ -> @SMatrix([ cos(θ) sin(θ)    0    0;
                             -sin(θ) cos(θ)    0    0;
                                0      0       1    0;
                                0      0       0    1])
    )

    for ax ∈ keys(rotation_matrices)
        quote
            $(Symbol(:rotation, ax))(θ::Real) = Transformation(rotation_matrices[$ax](θ),
                                                             rotation_matrices[$ax](-θ))
        end |> eval
    end
end
function translation(v::AbstractVector)
    size(v) == (3,) || raise(ArgumentError("argument 'v' has size = $(size(v)) but 'translate' requires an argument of size = (3,)")) 

    mat = Diagonal(ones(eltype(v), 4)) |> SMatrix{4, 4}
    mat⁻¹ = copy(mat)
    mat[end, 1:3]   =  v
    mat⁻¹[end, 1:3] = -v
    Transformation(mat, mat⁻¹)
end
translation(x::Real, y::Real, z::Real) = translation(Vec(x,y,z)) 
# TODO implement all the other functions and operations
