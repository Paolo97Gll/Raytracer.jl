abstract type RaytracerGeometry end

struct Vec{T<:Real} <: RaytracerGeometry
    x::T
    y::T
    z::T
end

struct Point{T<:Real} <: RaytracerGeometry
    x::T
    y::T
    z::T
end