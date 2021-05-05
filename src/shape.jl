"""
    Shape

An abstract type representing a shape.
"""
abstract type Shape end

"""
    HitRecord

A struct representing the result of an intersection between
a [`Ray`](@ref) and a [`Shape`](@ref).
"""
struct HitRecord
    world_point::Point
    normal::Normal
    surface_point::Vec2D
    t::Real
    ray::Ray
end


#####################################################################


"""
    Sphere

An abstract type representing a shape.
"""
struct Sphere <: Shape
    transformation::Transformation
end

function ray_intersection(s::Sphere, ray::Ray)
    inv_ray = ray * inverse(s.transformation)
    O = inv_ray.origin - ORIGIN
    # delta/4
    δ = (O * inv_ray.dir)^2 - norm²(inv_ray.dir) * (norm²(O) - 1)
    δ < 0 && return nothing
    # intersection ray-sphere
    t_1 = (-O * inv_ray.dir - δ) / norm²(inv_ray.dir)
    t_2 = (-O * inv_ray.dir + δ) / norm²(inv_ray.dir)
    # nearest point 
    if t_1 > inv_ray.tmin && t_1 < inv_ray.tmax
        hit_t = t_1
    elseif t_2 > inv_ray.tmin && t_2 < inv_ray.tmax
        hit_t = t_2
    else
        return nothing
    end
    hit_point = inv_ray(hit_t)
    # generate HitRecord
    world_point = s.transformation * hit_point
    normal = Normal(hit_point.v)
    normal = s.transformation * (normal ⋅ ray.dir < 0. ? normal : -normal)
    surface_point = Vec2D{eltype(ray)}(atan(hit_point.v[2]/hit_point.v[1])/2π, acos(hit_point.v[3])/π)
    HitRecord(world_point, normal, surface_point, hit_t, ray)
end