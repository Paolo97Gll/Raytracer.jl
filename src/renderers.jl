abstract type Renderer <: Function end

Base.@kwdef struct OnOffRenderer{T <: AbstractFloat} <: Renderer 
    world::World
    on_color::RGB{T} = one(RGB{T})
    off_color::RGB{T} = zero(RGB{T})
end

function (oor::OnOffRenderer)(ray::Ray)
    ray_intersection(ray, oor.world) !== nothing ? oor.on_color : oor.off_color
end

Base.@kwdef struct FlatRenderer{T <: AbstractFloat} <: Renderer 
    world::World
    background_color::RGB{T} = zero(RGB{T})
end

function (fr::FlatRenderer)(ray::Ray)
    (hit = ray_intersection(ray, fr.world)) !== nothing ? hit.material.emitted_radiance(hit.surface_point) + hit.material.brdf.pigment(hit.surface_point) : fr.background_color
end
