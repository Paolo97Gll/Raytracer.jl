# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

"""
    valid_intervals(ts::Vector)

Return a `Vector` of `Interval`s describing what ranges of the `t` parameter are internal to the shape, given its `ts` hit parameters.

For the function to work correctly `ts` must be of even length.
"""
function valid_intervals(ts::Vector)
    iseven(length(ts)) || throw(ArgumentError("given vector must have even length: got $ts"))
    sorted_ts = sort(ts)
    [Interval(t1, t2) for (t1, t2) ∈ zip(sorted_ts[begin:2:end], sorted_ts[begin+1:2:end])]
end

#######
# CSG

"""
    Rule

Enum type representing the hit point selection of a [`CSG`](@ref).

# Instances

- `UniteRule`: indicates that every hit point is valid
- `IntersectRule`: indicates that only hit points located inside of other shapes are valid
- `DiffRule`: indicates that only hit points outside of the `lbranch` and inside the `rbranch` are valid
- `FuseRule`: indicates that every hit point outside of other shapes is valid

See also: [`CSG`](@ref).
"""
@enum Rule begin
    UniteRule
    IntersectRule
    DiffRule
    FuseRule
end

"""
    CSG{R} <: CompositeShape

A [`Shape`](@ref) representing a Constructive Solid Geometry tree.

The behavior of the CSG tree is determined by the [`Rule`](@ref) `R`.

# Members

- `rbranch::Shape`: represents the right branch of the tree
- `lbranch::Shape`: represents the left branch of the tree
- `transformation::Transformation`: represents the [`Transformation`](@ref) of the whole composite shape

# External references

- Constructive Solid Geometry: https://en.wikipedia.org/wiki/Constructive_solid_geometry

"""
struct CSG{R} <: CompositeShape
    rbranch::Shape
    lbranch::Shape
    transformation::Transformation
    """
        CSG{R::Rule}(rbranch::Shape, lbranch::Shape)

    Constrcts an instance of a CSG tree with the given [`Rule`](@ref) and branches.
    """
    function CSG{R}(rbranch::Shape, lbranch::Shape; transformation::Transformation = Transformation()) where {R}
        R::Rule
        new{R}(rbranch, lbranch, transformation)
    end
end

function quick_ray_intersection(ray::Ray, csg::CSG)
    inv_ray = inv(csg.transformation) * ray
    ray_intersection(inv_ray, csg) |> !isnothing
end

"""
    UnionCSG

Alias for `CSG{UniteRule}`.

See also: [`CSG`](@ref), [`Rule`](@ref).
"""
const UnionCSG = CSG{UniteRule}

"""
    IntersectionCSG

Alias for `CSG{IntersectRule}`.

See also: [`CSG`](@ref), [`Rule`](@ref).
"""
const IntersectionCSG = CSG{IntersectRule}

"""
    DiffCSG

Alias for `CSG{DiffRule}`.

See also: [`CSG`](@ref), [`Rule`](@ref).
"""
const DiffCSG = CSG{DiffRule}

"""
    FusionCSG

Alias for `CSG{FuseRule}`.

See also: [`CSG`](@ref), [`Rule`](@ref).
"""
const FusionCSG = CSG{FuseRule}

"""
    union(s1::Shape, s2::Shape)

Construct a [`UnionCSG`](@ref) with the given shapes as `rbranch` and `lbranch` repectively.
"""
function Base.union(s1::Shape, s2::Shape)
    UnionCSG(s1, s2)
end

"""
    union(s::Shape, ss::Shape...)

Construct a [`UnionCSG`](@ref) binary tree, by recursively calling [`union`](@ref)`(::Shape, ::Shape)`.
"""
function Base.union(s::Shape, ss::Shape...)
    union(union(s, ss[begin:end ÷ 2]...), union(ss[end ÷ 2 + 1:end]...))
end

function Base.union(s1::Shape, s2::Shape, s3::Shape)
    union(union(s1, s2), s3)
end

"""
    intersect(s1::Shape, s2::Shape)

Construct a [`IntersectionCSG`](@ref) with the given shapes as `rbranch` and `lbranch` repectively.
"""
function Base.intersect(s1::Shape, s2::Shape)
    IntersectionCSG(s1, s2)
end

"""
    intersect(s::Shape, ss::Shape...)

Construct a [`IntersectionCSG`](@ref) binary tree, by recursively calling [`intersect`](@ref)`(::Shape, ::Shape)`.
"""
function Base.intersect(s::Shape, ss::Shape...)
    intersect(intersect(s, ss[begin:end ÷ 2]...), intersect(ss[(end ÷ 2 + 1):end]...))
end

function Base.intersect(s1::Shape, s2::Shape, s3::Shape)
    intersect(intersect(s1, s2), s3)
end

"""
    setdiff(s1::Shape, s2::Shape)

Construct a [`DiffCSG`](@ref) with the given shapes as `rbranch` and `lbranch` repectively.
"""
function Base.setdiff(s1::Shape, s2::Shape)
    DiffCSG(s1, s2)
end

"""
    setdiff(s::Shape, ss::Shape...)

Construct a [`DiffCSG`](@ref) between `s` and [`union`](@ref)`(ss...)`.
"""
function Base.setdiff(s::Shape, ss::Shape...)
    setdiff(s, union(ss...))
end

"""
    fuse(s1::Shape, s2::Shape)

Construct a [`FusionCSG`](@ref) with the given shapes as `rbranch` and `lbranch` repectively.
"""
function fuse(s1::Shape, s2::Shape)
    FusionCSG(s1, s2)
end

"""
    fuse(s::Shape, ss::Shape...)

Construct a [`FusionCSG`](@ref) binary tree, by recursively calling [`intersect`](@ref)`(::Shape, ::Shape)`.
"""
function fuse(s::Shape, ss::Shape...)
    fuse(fuse(s, ss[begin:end ÷ 2]...), fuse(ss[end ÷ 2 + 1:end]...))
end

function fuse(s1::Shape, s2::Shape, s3::Shape)
    fuse(fuse(s1, s2), s3)
end

###########
# UnionCSG

function ray_intersection(ray::Ray, csg::UnionCSG)
    inv_ray = inv(csg.transformation) * ray
    r_hit = ray_intersection(inv_ray, csg.rbranch)
    l_hit = ray_intersection(inv_ray, csg.lbranch)
    isnothing(r_hit) && return l_hit
    isnothing(l_hit) && return r_hit
    min(r_hit, l_hit)
end

function all_ray_intersections(ray::Ray, csg::UnionCSG)
    inv_ray = inv(csg.transformation) * ray
    append!(all_ray_intersections(inv_ray, csg.rbranch), all_ray_intersections(inv_ray, csg.lbranch))
end

function quick_ray_intersection(ray::Ray, csg::UnionCSG)
    inv_ray = inv(csg.transformation) * ray
    quick_ray_intersection(inv_ray, csg.rbranch) || quick_ray_intersection(inv_ray, csg.rbranch)
end

function get_all_ts(csg::UnionCSG, ray::Ray)
    inv_ray = inv(csg.transformation) * ray
    append!(get_all_ts(csg.rbranch, inv_ray), get_all_ts(csg.lbranch, inv_ray))
end

##################
# IntersectionCSG

function ray_intersection(ray::Ray, csg::IntersectionCSG)
    hits = filter(hit -> ray.tmin < hit.t < ray.tmax, all_ray_intersections(ray, csg))
    isempty(hits) && return nothing
    minimum(hits)
end

function all_ray_intersections(ray::Ray, csg::IntersectionCSG)
    inv_ray = inv(csg.transformation) * ray
    r_hits = all_ray_intersections(inv_ray, csg.rbranch)
    isempty(r_hits) && return Vector{HitRecord}()
    l_hits = all_ray_intersections(inv_ray, csg.lbranch)
    isempty(l_hits) && return Vector{HitRecord}()
    r_intervals = valid_intervals(r_hits)
    l_intervals = valid_intervals(l_hits)
    r_filter = filter(hit -> any(Ref(hit) .∈ l_intervals), r_hits)
    l_filter = filter(hit -> any(Ref(hit) .∈ r_intervals), l_hits)
    append!(r_filter, l_filter)
end

function quick_ray_intersection(ray::Ray, csg::IntersectionCSG)
    inv_ray = inv(csg.transformation) * ray
    r_ts = get_all_ts(csg.rbranch, inv_ray)
    isempty(r_ts) && return false
    l_ts = get_all_ts(csg.lbranch, inv_ray)
    isempty(l_ts) && return false
    r_intervals = valid_intervals(r_hits)
    l_intervals = valid_intervals(l_hits)
    any(t -> any(t .∈ l_intervals) && ray.tmin < t < ray.tmax, r_ts) ||
    any(t -> any(t .∈ r_intervals) && ray.tmin < t < ray.tmax, l_ts)
end

function get_all_ts(csg::IntersectionCSG, ray::Ray)
    inv_ray = inv(csg.transformation) * ray
    r_ts = get_all_ts(csg.rbranch, inv_ray)
    isempty(r_ts) && return Vector{Float32}()
    l_ts = get_all_ts(csg.lbranch, inv_ray)
    isempty(l_ts) && return Vector{Float32}()
    r_intervals = valid_intervals(r_ts)
    l_intervals = valid_intervals(l_ts)
    r_filter = filter(t -> any(t .∈ l_intervals), r_ts)
    l_filter = filter(t -> any(t .∈ r_intervals), l_ts)
    # @assert (length(r_filter) + length(l_filter) != 1) "Only one intersection for $(typeof(csg.rbranch)): $r_ts + $l_ts between $l_min and $l_max"
    append!(r_filter, l_filter)
end

##########
# DiffCSG

function ray_intersection(ray::Ray, csg::DiffCSG)
    hits = filter(hit -> ray.tmin < hit.t < ray.tmax, all_ray_intersections(ray, csg))
    isempty(hits) && return nothing
    minimum(hits)
end

function all_ray_intersections(ray::Ray, csg::DiffCSG)
    inv_ray = inv(csg.transformation) * ray
    r_hits = all_ray_intersections(inv_ray, csg.rbranch)
    isempty(r_hits) && return Vector{HitRecord}()
    l_hits = all_ray_intersections(inv_ray, csg.lbranch)
    isempty(l_hits) && return r_hits
    r_intervals = valid_intervals(r_hits)
    l_intervals = valid_intervals(l_hits)
    r_filter = filter(hit -> any(Ref(hit) .∉ l_intervals), r_hits)
    l_filter = filter(hit -> any(Ref(hit) .∈ r_intervals), l_hits)
    append!(r_filter, l_filter)
end

function quick_ray_intersection(ray::Ray, csg::DiffCSG)
    inv_ray = inv(csg.transformation) * ray
    # !isnothing(ray_intersection(inv_ray, csg))
    r_ts = get_all_ts(csg.rbranch, inv_ray)
    isempty(r_ts) && return false
    l_ts = get_all_ts(csg.lbranch, inv_ray)
    isempty(l_ts) && return any(t -> ray.tmin < t < ray.tmax, r_ts)

    # r_min, r_max = extrema(r_hits)
    # l_min, l_max = extrema(l_hits)
    r_intervals = valid_intervals(r_ts)
    l_intervals = valid_intervals(l_ts)
    any(t -> any(t .∉ l_intervals), r_ts) ||
    any(t -> any(t .∈ r_intervals), l_ts)
end

function get_all_ts(csg::DiffCSG, ray::Ray)
    inv_ray = inv(csg.transformation) * ray
    r_ts = get_all_ts(csg.rbranch, inv_ray)
    isempty(r_ts) && return Vector{Float32}()
    l_ts = get_all_ts(csg.lbranch, inv_ray)
    isempty(l_ts) && return r_ts
    # r_min, r_max = extrema(r_hits)
    # l_min, l_max = extrema(l_hits)
    r_intervals = valid_intervals(r_ts)
    l_intervals = valid_intervals(l_ts)
    r_filter = filter(t -> any(t .∉ l_intervals), r_ts)
    l_filter = filter(t -> any(t .∈ r_intervals), l_ts)
    append!(r_filter, l_filter)
end

###########
# FusionCSG

function ray_intersection(ray::Ray, csg::FusionCSG)
    hits = filter(hit -> ray.tmin < hit.t < ray.tmax, all_ray_intersections(ray, csg))
    isempty(hits) && return nothing
    minimum(hits)
end

function all_ray_intersections(ray::Ray, csg::FusionCSG)
    inv_ray = inv(csg.transformation) * ray
    r_hits = all_ray_intersections(inv_ray, csg.rbranch)
    l_hits = all_ray_intersections(inv_ray, csg.lbranch)
    isempty(r_hits) && return l_hits
    isempty(l_hits) && return r_hits
    r_intervals = valid_intervals(r_hits)
    l_intervals = valid_intervals(l_hits)
    r_filter = filter(hit -> any(Ref(hit) .∉ l_intervals), r_hits)
    l_filter = filter(hit -> any(Ref(hit) .∉ r_intervals), l_hits)
    isempty(r_filter) && return l_filter
    isempty(l_filter) && return r_filter
    append!(r_filter, l_filter)
end

function quick_ray_intersection(ray::Ray, csg::FusionCSG)
    inv_ray = inv(csg.transformation) * ray
    r_ts = get_all_ts(csg.rbranch, inv_ray)
    l_ts = get_all_ts(csg.lbranch, inv_ray)
    isempty(r_ts) && return !isempty(l_ts)
    isempty(l_ts) && return true
    r_intervals = valid_intervals(r_ts)
    l_intervals = valid_intervals(l_ts)
    any(t -> any(t .∉ l_intervals), r_ts) ||
    any(t -> any(t .∉ r_intervals), l_ts)
end

function get_all_ts(csg::FusionCSG, ray::Ray)
    inv_ray = inv(csg.transformation) * ray
    r_ts = get_all_ts(csg.rbranch, inv_ray)
    l_ts = get_all_ts(csg.lbranch, inv_ray)
    isempty(r_ts) && return l_ts
    isempty(l_ts) && return r_ts
    r_intervals = valid_intervals(r_ts)
    l_intervals = valid_intervals(l_ts)
    r_filter = filter(t -> any(t .∉ l_intervals), r_ts)
    l_filter = filter(t -> any(t .∉ r_intervals), l_ts)
    append!(r_filter, l_filter)
end
