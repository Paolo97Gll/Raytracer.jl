# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# (C) 2021 Samuele Colombo, Paolo Galli
#
# file:
#   image_tracer.jl
# description:
#   TODO fill

"""
    ImageTracer{T}

Agent struct filling an [`HdrImage`](@ref) with the information collected by a [`Camera`](@ref).

To fill an image store it into `ImageTracer` along with the desired 
camera and apply [`fire_all_rays`](@ref) to it. Alternatively apply iteratively [`fire_ray`](@ref) 
on the desired ranges.
"""
struct ImageTracer{T}
    image::HdrImage{T}
    camera::Camera
end

eltype(::ImageTracer{T}) where {T} = T

"""
    fire_ray(tracer, col, row; u_pixel= 0.5, v_pixel = 0.5)

Shoot a [`Ray`](@ref) through the pixel `(col, row)`

The parameters `col` and `row` are measured in the same way as they are in [`HdrImage`](@ref): the bottom left
corner is placed at `(0, 0)`. The values of `u_pixel` and `v_pixel` are floating-point numbers in the range
`[0, 1]`: they specify where the ray should cross the pixel; passing 0.5 to both means that the ray will pass
through the pixel's center.
"""
function fire_ray(tracer::ImageTracer, 
                  col::Integer, row::Integer; 
                  u_pixel::AbstractFloat = 0.5, 
                  v_pixel::AbstractFloat = 0.5)
    u = ((col-1) + u_pixel) / size(tracer.image)[1]
    v = 1.0 - ((row-1) + v_pixel) / size(tracer.image)[2]
    fire_ray(tracer.camera, u, v, eltype(eltype(tracer)))
end

"""
    fire_all_rays(tracer, func)

Fire a [`Ray`](@ref) accross each pixel of the image

For each pixel in the image contained into `tracer` (instance of [`ImageTracer`](@ref)), fire one ray. Then,
pass it to the function `func`, which must accept a `Ray` as its only parameter and must return a `[RGB](@ref)`
instance containing the color to assign to that pixel in the image.
"""
function fire_all_rays(tracer::ImageTracer, func::Function)
    # rangerow, rangecol = axes(tracer.image)
    @showprogress for ind ∈ CartesianIndices(tracer.image.pixel_matrix) #row ∈ rangerow, col ∈ rangecol
        ray = fire_ray(tracer, Tuple(ind)...)
        tracer.image.pixel_matrix[ind] = func(ray)
    end
end