# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Implementation of HdrImage for the manipulation and elaboration of and HDR image
# TODO write docstrings


"""
    HdrImage

Wrapper of a `Matrix` of elements of type `RGB{Float32}`, used to represent an image in hdr format.
"""
struct HdrImage
    pixel_matrix::Matrix{RGB{Float32}}
end

"""
    HdrImage(img_width, img_height)

Construct an `HdrImage` wrapping a zero-initialized matrix of size `(img_width, img_height)`.

# Examples
```jldoctest
julia> a = HdrImage(3, 2)
3x2 HdrImage:
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
```
"""
HdrImage(img_width::Integer, img_height::Integer) = HdrImage(zeros(RGB{Float32}, img_width, img_height))

"""
    HdrImage(arr, img_width, img_height)
    HdrImage(arr, shape)

Construct an `HdrImage` wrapping a matrix obtained from `reshape`.

# Examples
```jldoctest
julia> arr = [RGB( 1.,  2.,  3.), RGB( 4.,  5.,  6.), RGB( 7.,  8.,  9.),
              RGB(10., 11., 12.), RGB(13., 14., 15.), RGB(16., 17., 18.)];

julia> a = HdrImage(arr, 3, 2)
3x2 HdrImage:
 (1.0 2.0 3.0)  (10.0 11.0 12.0)
 (4.0 5.0 6.0)  (13.0 14.0 15.0)
 (7.0 8.0 9.0)  (16.0 17.0 18.0)
```
"""
HdrImage(arr::AbstractArray{<:Any, 1}, im_width::Integer, im_height::Integer) = HdrImage(reshape(arr, im_width, im_height))
HdrImage(arr::AbstractArray{<:Any, 1}, shape) = HdrImage(reshape(arr, shape))


#############
# Iterations


length(image::HdrImage) = length(image.pixel_matrix)

firstindex(image::HdrImage) = firstindex(image.pixel_matrix)
firstindex(image::HdrImage, d) = firstindex(image.pixel_matrix, d)

lastindex(image::HdrImage) = lastindex(image.pixel_matrix)
lastindex(image::HdrImage, d) = lastindex(image.pixel_matrix, d)

getindex(image::HdrImage, inds...) = getindex(image.pixel_matrix, inds...)

setindex!(image::HdrImage, value, key) = setindex!(image.pixel_matrix, value, key)
setindex!(image::HdrImage, X, inds...) = setindex!(image.pixel_matrix, X, inds...)

iterate(image::HdrImage, state = 1) = state > lastindex(image) ? nothing : (image[state], state + 1)


###############
# Broadcasting


axes(image::HdrImage) = axes(image.pixel_matrix)
axes(image::HdrImage, d) = axes(image.pixel_matrix, d)

broadcastable(image::HdrImage) = image
broadcastable(::Type{<:HdrImage}) = HdrImage

BroadcastStyle(::Type{<:HdrImage}) = Style{HdrImage}()
BroadcastStyle(::Style{HdrImage}, ::BroadcastStyle) = Style{HdrImage}()

copy(bc::Broadcasted{Style{HdrImage}}) = copy(convert(Broadcasted{Broadcast.DefaultArrayStyle{RGB{Float32}}}, bc))


###############
# Tone mapping


function average_luminosity(image::HdrImage; δ::Float32 = eps(Float32))
    10^(sum(map(x -> log10(δ + luminosity(x)), image))/length(image))
end

function normalize_image(image::HdrImage, α::Float32; luminosity::Float32 = average_luminosity(image))
    HdrImage([α / luminosity * pix for pix ∈ image], size(image))
end

clamp_image(image::HdrImage) = HdrImage(clamp.(image))

γ_correction(image::HdrImage, γ::Float32) = HdrImage(γ_correction.(image, γ))


################
# Miscellaneous


show(io::IO, image::HdrImage) = print_matrix(io, image.pixel_matrix)

function show(io::IO, ::MIME"text/plain", image::HdrImage)
    println(io, "$(join(map(string, size(image)), "x")) $(typeof(image)):")
    print_matrix(io, image.pixel_matrix)
end

eltype(::HdrImage) = RGB{Float32}

fill!(image::HdrImage, x) = HdrImage(fill!(image.pixel_matrix, x))

size(image::HdrImage) = size(image.pixel_matrix)
