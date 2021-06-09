# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Trace utility to generate an image by shooting light rays through each of its pixels


"""
    struct ImageTracer

Trace an image by shooting light rays through each of its pixels.

To fill an image store it into `ImageTracer` along with the desired camera and apply [`fire_all_rays!`](@ref)
to it. Alternatively apply iteratively [`fire_ray(::ImageTracer, ::Int, ::Int; ::Float32, ::Float32)`](@ref)
on the desired ranges.

# Members

- `image::HdrImage`: a [`HdrImage`](@ref) in which save the rendered image.
- `camera::Camera`: a [`Camera`](@ref) holding the observer informations.
- `samples_per_side::Int`: the number of samples per side of a pixel for antialiasing algorithm.
- `rng::PCG`: a [`PCG`](@ref) random number generator for antialiasing algorithm.

If `samples_per_side` is larger than zero, antialiasing will be applied to each pixel in the image,
using the random number generator `rng`.
"""
struct ImageTracer
    image::HdrImage
    camera::Camera
    samples_per_side::Int
    rng::PCG
end

@doc """
    ImageTracer(image::HdrImage, camera::Camera, samples_per_side::Int, rng::PCG)

Constructor for an [`ImageTracer`](@ref) instance.
""" ImageTracer(::HdrImage, ::Camera, ::Int, ::PCG)

"""
    ImageTracer(image::HdrImage, camera::Camera
                ; samples_per_side::Int = 0,
                  rng::PCG = PCG())

Construct a [`ImageTracer`](@ref).

If `samples_per_side` is not specified, antialiasing will be disabled and `rng` is ignored.
"""
function ImageTracer(image::HdrImage, camera::Camera;
                     samples_per_side::Int = 0,
                     rng::PCG = PCG())
    ImageTracer(image, camera, samples_per_side, rng)
end

"""
    fire_ray(tracer::ImageTracer, col::Int, row::Int
             ; u_pixel::Float32 = 0.5f0,
               v_pixel::Float32 = 0.5f0)

Shoot a [`Ray`](@ref) through the pixel `(col, row)` of the image contained in an [`ImageTracer`], using its
camera informations.

The function use the `fire_ray` function of the associated camera ([`fire_ray(::OrthogonalCamera, ::Float32, ::Float32)`](@ref),
    [`fire_ray(::PerspectiveCamera, ::Float32, ::Float32)`](@ref))

The parameters `col` and `row` are measured in the same way as they are in [`HdrImage`](@ref): the bottom left
corner is placed at ``(0, 0)``. The values of `u_pixel` and `v_pixel` are floating-point numbers in the range
``[0, 1]``: they specify where the ray should cross the pixel; passing 0.5 to both means that the ray will pass
through the pixel's center.

See also: [`fire_all_rays!`](@ref)
"""
function fire_ray(tracer::ImageTracer, col::Int, row::Int;
                  u_pixel::Float32 = 0.5f0,
                  v_pixel::Float32 = 0.5f0)
    size_col, size_raw = size(tracer.image)
    u = (col - 1f0 + u_pixel) / size_col
    v = 1f0 - (row - 1f0 + v_pixel) / size_raw
    fire_ray(tracer.camera, u, v)
end

function fire_all_rays_loop(tracer::ImageTracer, ind::CartesianIndex{2}, renderer::Renderer)
    if tracer.samples_per_side > 0
        cum_color = BLACK
        for inter_pixel_row in 0:tracer.samples_per_side-1
            for inter_pixel_col in 0:tracer.samples_per_side-1
                u_pixel = (inter_pixel_col + rand(tracer.rng, Float32)) / tracer.samples_per_side
                v_pixel = (inter_pixel_row + rand(tracer.rng, Float32)) / tracer.samples_per_side
                ray = fire_ray(tracer, Tuple(ind)..., u_pixel=u_pixel, v_pixel=v_pixel)
                cum_color += renderer(ray)
            end
        end
        tracer.image.pixel_matrix[ind] = cum_color * (1 / tracer.samples_per_side^2)
    else
        ray = fire_ray(tracer, Tuple(ind)...)
        tracer.image.pixel_matrix[ind] = renderer(ray)
    end
end

"""
    fire_all_rays!(tracer::ImageTracer, renderer::Renderer
                   ; use_threads::Bool = true,
                     enable_progress_bar::Bool = true)

Render an image with informations stored in an [`ImageTracer`](@ref) using the specified [`Renderer`](@ref).

This function apply iteratively [`fire_ray(::ImageTracer, ::Int, ::Int; ::Float32, ::Float32)`](@ref) for
each pixel in the image contained in `tracer` using its camera, and then render the point using `renderer`.

If `use_threads` is `true`, the function will use the `Threads.@threads` macro to parallelize the computation.

If `enable_progress_bar` is `true`, the function will display a progress bar during the computation; this is thread safe.

See also: [`fire_ray(::ImageTracer, ::Int, ::Int; ::Float32, ::Float32)`](@ref)
"""
function fire_all_rays!(tracer::ImageTracer, renderer::Renderer;
                        use_threads::Bool = true,
                        enable_progress_bar::Bool = true)
    indices = CartesianIndices(tracer.image.pixel_matrix)
    p = Progress(length(indices), color=:white, enabled=enable_progress_bar)
    if use_threads
        Threads.@threads for ind ∈ indices
            fire_all_rays_loop(tracer, ind, renderer)
            next!(p)
        end
    else
        for ind ∈ indices
            fire_all_rays_loop(tracer, ind, renderer)
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
