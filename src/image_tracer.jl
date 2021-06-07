# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Trace utility to generate an image by shooting light rays through each of its pixels
# TODO write docstrings


"""
    ImageTracer{T}

Agent struct filling an [`HdrImage`](@ref) with the information collected by a [`Camera`](@ref).

To fill an image store it into `ImageTracer` along with the desired 
camera and apply [`fire_all_rays`](@ref) to it. Alternatively apply iteratively [`fire_ray`](@ref) 
on the desired ranges.
"""
struct ImageTracer
    image::HdrImage
    camera::Camera
    rng::PCG

    ImageTracer(image::HdrImage, camera::Camera, rng::PCG = PCG()) = new(image, camera, rng)
end


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
                  u_pixel::Float32 = 0.5f0, 
                  v_pixel::Float32 = 0.5f0)
    size_col, size_raw = size(tracer.image)
    u = (col - 1f0 + u_pixel) / size_col
    v = 1f0 - (row - 1f0 + v_pixel) / size_raw
    fire_ray(tracer.camera, u, v)
end

"""
    fire_all_rays!(tracer, func)

Fire a [`Ray`](@ref) accross each pixel of the image

For each pixel in the image contained into `tracer` (instance of [`ImageTracer`](@ref)), fire one ray. Then,
pass it to the function `func`, which must accept a `Ray` as its only parameter and must return a `[RGB](@ref)`
instance containing the color to assign to that pixel in the image.
"""

function fire_all_rays_loop(tracer::ImageTracer, ind::CartesianIndex{2}, func::Function)
    # TODO implement antialiasing: need to modify imagetracer since it need a pcg inside and other parameters
    ray = fire_ray(tracer, Tuple(ind)...)
    tracer.image.pixel_matrix[ind] = func(ray)
end

function fire_all_rays!(tracer::ImageTracer, func::Function; use_threads::Bool = true, enable_progress_bar::Bool = true)
    indices = CartesianIndices(tracer.image.pixel_matrix)
    p = Progress(length(indices), color=:white, enabled=enable_progress_bar)
    # for ind ∈ indices
    #     fire_all_rays_loop(tracer, ind, func)
    #     next!(p)
    # end
    # FIXME find a more clean way to do this
    if use_threads
        Threads.@threads for ind ∈ indices
            fire_all_rays_loop(tracer, ind, func)
            next!(p)
        end
    else
        for ind ∈ indices
            fire_all_rays_loop(tracer, ind, func)
            next!(p)
        end
    end
end


################
# Miscellaneous


function show(io::IO, ::MIME"text/plain", t::ImageTracer)
    println(io, typeof(t), " with camera of type ", typeof(t.camera))
    print(io, "image of size ", join(size(t.image), "x"), " and of type ", typeof(t.image));
end

eltype(::ImageTracer) = Float32
eltype(::Type{ImageTracer}) = Float32
