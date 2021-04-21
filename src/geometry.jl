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

# docstrings
let docmsg = V ->"""
        $V{T} <: FieldVector{3, T}
    
    A $(V == :Normal ? "pseudo-" : "")vector in 3D space.
    """
    @doc docmsg(:Vec)    Vec
    @doc docmsg(:Normal) Normal
end

#####################################################################

"""
    Point{T}

A point in a 3D space. Implemented as a wrapper struct around an `SVector{3, T}`.
"""
struct Point{T}
    v::SVector{3, T}
end

# Convenience constructors
"""
    Point(x, y, z)
    Point(p::AbstractVector)

Construct a `Point` with given coordinates.

If an `AbstractVector` is provided as argument it must have a size = (3,)
"""
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

"""
    isconsistent(t)

Return `true` if `t.m * t.invm` is similar to the identity matrix.

Mainly used for testing and to verify matrices haven't been mutated.
"""
isconsistent(t::Transformation) = (t.m * t.invm) ≈ I(4)


(*)(t1::Transformation, t2::Transformation) = Transformation(t1.m * t2.m, t2.invm * t1.invm)
(*)(t ::Transformation, v ::Vec)            = @view(t.m[1:3,1:3]) * v
(*)(t ::Transformation, n ::Normal)         = transpose(@view(t.invm[1:3,1:3])) * n
(*)(t ::Transformation, p ::Point)          = t.m * SVector(p.v..., one(eltype(p))) 

"""
    inverse(t)

Return the inverse `Transformation`.

Returns a `Transformation` which has the `m` and `invm` fields swapped. 
Note that the returned `Transformation` may have a different eltype with respect of the given one.

#Examples
```jldoctest
julia> t = Transformation(Diagonal([1, 2, 3, 1]))
julia> inverse(t)
```
"""
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

    # docstrings
    let docmsg = ax -> """
            rotation$ax(θ)

        Return a `Transformation` that rotates a 3D vector field of the given angle around the $ax-axis.
        
        If an `AbstractVector` is provided as argument it must have a size = (3,)
        
        #Examples
        ```jldoctest
        julia> rotation$ax(1, 2, 3)
        
        ```            
        
        ```jldoctest
        julia> rotation$ax([1, 2, 3])
        ```
        """
        @doc docmsg(:X) rotationX
        @doc docmsg(:Y) rotationY
        @doc docmsg(:Z) rotationZ
    end
end

"""
    translation(x, y, z)
    translation(v)

Return a `Transformation` that translates a 3D vector field of the given coordinates.

If an `AbstractVector` is provided as argument it must have a size = (3,)

#Examples
```jldoctest
julia> translation(1, 2, 3)
```

```jldoctest
julia> translation([1, 2, 3])
```
"""
function translation(v::AbstractVector)
    size(v) == (3,) || raise(ArgumentError("argument 'v' has size = $(size(v)) but 'translate' requires an argument of size = (3,)")) 

    mat = Diagonal(ones(eltype(v), 4)) |> SMatrix{4, 4}
    mat⁻¹ = copy(mat)
    mat[end, 1:3]   =  v
    mat⁻¹[end, 1:3] = -v
    Transformation(mat, mat⁻¹)
end
translation(x::Real, y::Real, z::Real) = translation(Vec(x,y,z)) 

"""
    scaling(x, y, z)
    scaling(s::Real)
    scaling(v::AbstractVector)

Return a `Transformation` that scales a 3D vector field of a given factor for each axis.

If a single `Real` is provided as argument then the scaling is considered uniform.
If an `AbstractVector` is provided as argument it must have a size = (3,)

#Examples
```jldoctest
julia> scaling(1, 2, 3)
```

```jldoctest
julia> scaling(2)
```

```jldoctest
julia> scaling([1, 2, 3])
```
"""
function scaling(x::Real, y::Real, z::Real)
    Transformation(Diagonal(        [x, y, z, true]), 
                   Diagonal(true ./ [x, y, z, true])) # NOTE: the use of true is to avoid unwanted promotions
end
scaling(s::Real) = scaling(s, s, s)
function scaling(v::AbstractVector) 
    size(v) == (3,) || raise(ArgumentError("argument 'v' has size = $(size(v)) but 'scaling' requires an argument of size = (3,)"))
    
    scaling(v...)
end