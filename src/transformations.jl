# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Implementation of transformations (generics, translations, rotations, ...)

"""
    Transformation

A wrapper around two 4x4 matrices representing a transformation for [`Vec`](@ref), [`Normal`](@ref), and [`Point`](@ref) instances.

A 4x4 matrix is needed to use the properties of homogeneous coordinates in 3D space. Storing the inverse of the transformation 
significantly increases performance at the cost of memory space.

Members:
- `m` ([`StaticArrays.SMatrix`](@ref)`{4, 4, Float32}`): the homogeneous matrix representation of the transformation. Default value is the identity matrix.
- `invm` ([`StaticArrays.SMatrix`](@ref)`{4, 4, Float32}`): the homogeneous matrix representation of the inverse transformation. 
  Default value is the inverse of `m` calculated through the [`Base.inv`](@ref) function.

# Examples
```jldoctest
julia> Transformation()
4x4 Transformation:
Matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0  0.0f0
 0.0f0  1.0f0  0.0f0  0.0f0
 0.0f0  0.0f0  1.0f0  0.0f0
 0.0f0  0.0f0  0.0f0  1.0f0
Inverse matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0  0.0f0
 0.0f0  1.0f0  0.0f0  0.0f0
 0.0f0  0.0f0  1.0f0  0.0f0
 0.0f0  0.0f0  0.0f0  1.0f0
```
"""
struct Transformation
    m::SMatrix{4, 4, Float32}
    invm::SMatrix{4, 4, Float32}
    
    function Transformation(m::SMatrix{4, 4, Float32} = SMatrix{4, 4, Float32}(I(4)),
                            invm::SMatrix{4, 4, Float32} = inv(m))
        new(m, invm)
    end
end

"""
    Transformation(m)
    Transformation(m, invm)

Construct a `Transformation` instance from `m` and `invm`. The elements of the matrix will be casted to `Float32`.

If any argument is an [`AbstractMatrix`](@ref) it will be implicitly casted to a [`StaticArrays.SMatrix`](@ref) to increase performance.

# Examples
```jldoctest; setup = :(import StaticArrays)
julia> Transformation(StaticArrays.SMatrix{4,4}([1 0 0 0; 0 2 0 0; 0 0 4 0; 0 0 0 1]))
4x4 Transformation:
Matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0  0.0f0
 0.0f0  2.0f0  0.0f0  0.0f0
 0.0f0  0.0f0  4.0f0  0.0f0
 0.0f0  0.0f0  0.0f0  1.0f0
Inverse matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0   0.0f0
 0.0f0  0.5f0  0.0f0   0.0f0
 0.0f0  0.0f0  0.25f0  0.0f0
 0.0f0  0.0f0  0.0f0   1.0f0

julia> Transformation([1 0 0 0; 0 2 0 0; 0 0 4 0; 0 0 0 1])
4x4 Transformation:
Matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0  0.0f0
 0.0f0  2.0f0  0.0f0  0.0f0
 0.0f0  0.0f0  4.0f0  0.0f0
 0.0f0  0.0f0  0.0f0  1.0f0
Inverse matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0   0.0f0
 0.0f0  0.5f0  0.0f0   0.0f0
 0.0f0  0.0f0  0.25f0  0.0f0
 0.0f0  0.0f0  0.0f0   1.0f0
```

```jldoctest; setup = :(import LinearAlgebra)
julia> Transformation(LinearAlgebra.Diagonal([1,2,4,1]))
4x4 Transformation:
Matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0  0.0f0
 0.0f0  2.0f0  0.0f0  0.0f0
 0.0f0  0.0f0  4.0f0  0.0f0
 0.0f0  0.0f0  0.0f0  1.0f0
Inverse matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0   0.0f0
 0.0f0  0.5f0  0.0f0   0.0f0
 0.0f0  0.0f0  0.25f0  0.0f0
 0.0f0  0.0f0  0.0f0   1.0f0
```
"""
Transformation(m::AbstractMatrix) = Transformation(SMatrix{4, 4, Float32}(m))
Transformation(m::AbstractMatrix, invm::AbstractMatrix) = Transformation(SMatrix{4, 4, Float32}(m), SMatrix{4, 4, Float32}(invm))


################
# Miscellaneous


function show(io::IO, ::MIME"text/plain", t::Transformation)
    println(io, "4x4 $(typeof(t)):")
    println(io, "Matrix of type ", typeof(t.m), ":")
    print_matrix(io, t.m)
    println(io, "\nInverse matrix of type ", typeof(t.invm), ":")
    print_matrix(io, t.invm)
end

eltype(::Transformation) = Float32
eltype(::Type{Transformation}) = Float32

"""
    isconsistent(t)

Return `true` if `t.m * t.invm` is similar to the identity matrix.

Mainly used for testing and to verify matrices haven't been mutated.
"""
isconsistent(t::Transformation) = (t.m * t.invm) ≈ I(4)

(≈)(t1::Transformation, t2::Transformation) = t1.m ≈ t2.m && t1.invm ≈ t2.invm

(*)(t1::Transformation, t2::Transformation) = Transformation(t1.m * t2.m, t2.invm * t1.invm)
(*)(t ::Transformation, v ::Vec) = Vec(@view(t.m[1:3,1:3]) * v)
(*)(t ::Transformation, n ::Normal) = Normal(transpose(@view(t.invm[1:3,1:3])) * n)
function (*)(t ::Transformation, p ::Point)
    res = t.m * SVector(p.v..., one(eltype(p)))
    res = res[end] == 1 ? res : res/res[end]
    Point(@view(res[1:3]))
end


##########
# Inverse 


"""
    inv(t)

Return the inverse [`Transformation`](@ref).

Returns a `Transformation` which has the `m` and `invm` fields swapped. 

#Examples
```jldoctest; setup = :(using LinearAlgebra: Diagonal) 
julia> t = Transformation(Diagonal([1, 2, 3, 1]))
4x4 Transformation:
Matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0  0.0f0
 0.0f0  2.0f0  0.0f0  0.0f0
 0.0f0  0.0f0  3.0f0  0.0f0
 0.0f0  0.0f0  0.0f0  1.0f0
Inverse matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0         0.0f0
 0.0f0  0.5f0  0.0f0         0.0f0
 0.0f0  0.0f0  0.33333334f0  0.0f0
 0.0f0  0.0f0  0.0f0         1.0f0

julia> inv(t)
4x4 Transformation:
Matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0         0.0f0
 0.0f0  0.5f0  0.0f0         0.0f0
 0.0f0  0.0f0  0.33333334f0  0.0f0
 0.0f0  0.0f0  0.0f0         1.0f0
Inverse matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0  0.0f0
 0.0f0  2.0f0  0.0f0  0.0f0
 0.0f0  0.0f0  3.0f0  0.0f0
 0.0f0  0.0f0  0.0f0  1.0f0
 ```
"""
inv(t::Transformation) = Transformation(t.invm, t.m)


############
# Rotations


let rotation_matrices = Dict(
        :X => :(@SMatrix(Float32[   1      0      0     0;
                                    0    cos(θ) -sin(θ) 0;
                                    0    sin(θ)  cos(θ) 0;
                                    0      0      0     1])),
        :Y => :(@SMatrix(Float32[ cos(θ)   0     sin(θ) 0;
                                    0      1      0     0;
                                 -sin(θ)   0     cos(θ) 0;
                                    0      0      0     1])),
        :Z => :(@SMatrix(Float32[ cos(θ) -sin(θ)  0     0;
                                  sin(θ)  cos(θ)  0     0;
                                    0      0      1     0;
                                    0      0      0     1]))
    )

    for (ax, mat) ∈ pairs(rotation_matrices)
        quote
            function $(Symbol(:rotation, ax))(θ::Real) 
                m = $mat
                Transformation(m, transpose(m))
            end
        end |> eval
    end

    # docstrings
    let docmsg = (ax, mat) -> """
            rotation$ax(θ)

        Return a [`Transformation`](@ref) that rotates a 3D vector field of the given angle around the $ax-axis.
        
        If an `AbstractVector` is provided as argument it must have a size = (3,)
        
        # Examples
        ```jldoctest
        julia> rotation$ax(π/4)
        $(replace(repr(MIME("text/plain"), mat), "Raytracer." => "" ))
        ```            
        """
        @doc docmsg(:X, rotationX(π/4)) rotationX
        @doc docmsg(:Y, rotationY(π/4)) rotationY
        @doc docmsg(:Z, rotationZ(π/4)) rotationZ
    end
end


###############
# Translations


"""
    translation(x, y, z)
    translation(v)

Return a [`Transformation`](@ref) that translates a 3D vector field of the given coordinates.

If an `AbstractVector` is provided as argument it must have a size = (3,)

# Examples
```jldoctest
julia> translation(1, 2, 3)
4x4 Transformation:
Matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0  1.0f0
 0.0f0  1.0f0  0.0f0  2.0f0
 0.0f0  0.0f0  1.0f0  3.0f0
 0.0f0  0.0f0  0.0f0  1.0f0
Inverse matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0  -1.0f0
 0.0f0  1.0f0  0.0f0  -2.0f0
 0.0f0  0.0f0  1.0f0  -3.0f0
 0.0f0  0.0f0  0.0f0   1.0f0
```

```jldoctest
julia> translation([1, 2, 3])
4x4 Transformation:
Matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0  1.0f0
 0.0f0  1.0f0  0.0f0  2.0f0
 0.0f0  0.0f0  1.0f0  3.0f0
 0.0f0  0.0f0  0.0f0  1.0f0
Inverse matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0  -1.0f0
 0.0f0  1.0f0  0.0f0  -2.0f0
 0.0f0  0.0f0  1.0f0  -3.0f0
 0.0f0  0.0f0  0.0f0   1.0f0
```
"""
function translation(v::AbstractVector)
    size(v) == (3,) || raise(ArgumentError("argument 'v' has size = $(size(v)) but 'translate' requires an argument of size = (3,)")) 

    mat = Diagonal(ones(eltype(v), 4)) |> MMatrix{4, 4}
    mat⁻¹ = copy(mat)
    mat[1:3, end]   =  v
    mat⁻¹[1:3, end] = -v
    Transformation(mat, mat⁻¹)
end

translation(x::Real, y::Real, z::Real) = translation([x,y,z]) 


##########
# Scaling


"""
    scaling(x, y, z)
    scaling(s::Real)
    scaling(v::AbstractVector)

Return a [`Transformation`](@ref) that scales a 3D vector field of a given factor for each axis.

If a single `Real` is provided as argument then the scaling is considered uniform.
If an `AbstractVector` is provided as argument it must have a size = (3,)

# Examples
```jldoctest
julia> scaling(1, 2, 3)
4x4 Transformation:
Matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0  0.0f0
 0.0f0  2.0f0  0.0f0  0.0f0
 0.0f0  0.0f0  3.0f0  0.0f0
 0.0f0  0.0f0  0.0f0  1.0f0
Inverse matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0         0.0f0
 0.0f0  0.5f0  0.0f0         0.0f0
 0.0f0  0.0f0  0.33333334f0  0.0f0
 0.0f0  0.0f0  0.0f0         1.0f0
```

```jldoctest
julia> scaling(2)
4x4 Transformation:
Matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 2.0f0  0.0f0  0.0f0  0.0f0
 0.0f0  2.0f0  0.0f0  0.0f0
 0.0f0  0.0f0  2.0f0  0.0f0
 0.0f0  0.0f0  0.0f0  1.0f0
Inverse matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 0.5f0  0.0f0  0.0f0  0.0f0
 0.0f0  0.5f0  0.0f0  0.0f0
 0.0f0  0.0f0  0.5f0  0.0f0
 0.0f0  0.0f0  0.0f0  1.0f0
```

```jldoctest
julia> scaling([1, 2, 3])
4x4 Transformation:
Matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0  0.0f0
 0.0f0  2.0f0  0.0f0  0.0f0
 0.0f0  0.0f0  3.0f0  0.0f0
 0.0f0  0.0f0  0.0f0  1.0f0
Inverse matrix of type StaticArrays.SMatrix{4, 4, Float32, 16}:
 1.0f0  0.0f0  0.0f0         0.0f0
 0.0f0  0.5f0  0.0f0         0.0f0
 0.0f0  0.0f0  0.33333334f0  0.0f0
 0.0f0  0.0f0  0.0f0         1.0f0
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
