# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

#######
# Cube

"""
    struct Cube <: SimpleShape

A [`SimpleShape`](@ref) representing a cube of unitary size.

# Members

- `transformation::Transformation`: the `Transformation` associated with the cube.
- `material::Material`: the [`Material`](@ref) of the cube.
"""
Base.@kwdef struct Cube <: SimpleShape
    transformation::Transformation = Transformation()
    material::Material = Material()
end

@doc """
    Cube(transformation::Transformation, material::Material)

Constructor for a [`Cube`](@ref) instance.
""" Cube(::Transformation, ::Material)

@doc """
    Cube(transformation::Transformation = Transformation(),
           material::Material = Material())

Constructor for a [`Cube`](@ref) instance.
""" Cube(; ::Transformation, ::Material)

function get_t(::Type{Cube}, ray::Ray)
    get_t(scaling(2f0) * ray, AABB(Point(fill(1f0, 3)), Point(fill(-1f0, 3))))
end

function get_all_ts(::Type{Cube}, ray::Ray)
    get_all_ts(scaling(2f0) * ray, AABB(Point(fill(1f0, 3)), Point(fill(-1f0, 3))))    
end

function get_uv(::Type{Cube}, point::Point)
    x, y, z = point
    abs_point = point.v .|> abs |> Point
    maxval, index = findmax(abs_point.v)

    @assert 1 <= index <= 3

    ispos = point[index] > 0

    if index == 1 
        uc = ispos ? z : -z
        vc = y
        offset = (ispos ? 2 : 0, 1)  
    elseif index == 2
        uc = x;
        vc = ispos ? z : -z
        offset = (1, ispos ? 2 : 0)
    else 
        uc = ispos ? -x : x
        vc = y
        offset = (ispos ? 3 : 1, 1)
    end

    @.((offset + 0.5f0 * ((uc, vc) / maxval + 1f0))/(4f0, 3f0)) |> Vec2D
end

function get_normal(::Type{Cube}, point::Point, ray::Ray)
    abs_point = point.v .|> abs |> Point
    _, index = findmax(abs_point.v)

    @assert 1 <= index <= 3

    s = -sign(point[index] * ray.dir[index])

    @assert s != 0

    [i == index ? s * 1f0 : 0f0 for i ∈ 1:3] |> Normal{true}
end
