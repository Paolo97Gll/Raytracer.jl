# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Implementation of HdrImage for the manipulation and elaboration of and HDR image


"""
    HdrImage

Wrapper of a `Matrix` of elements of type `RGB{Float32}`, used to represent an image in hdr format.
"""
struct HdrImage
    pixel_matrix::Matrix{RGB{Float32}}
end

"""
    HdrImage(img_width::Integer, img_height::Integer)

Construct an [`HdrImage`](@ref) wrapping a zero-initialized matrix of size `(img_width, img_height)`.

# Examples

```jldoctest
julia> HdrImage(3, 2)
3x2 HdrImage:
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
```
"""
HdrImage(img_width::Integer, img_height::Integer) = HdrImage(zeros(RGB{Float32}, img_width, img_height))

"""
    HdrImage(arr::AbstractArray{<:Any, 1}, im_width::Integer, im_height::Integer)
    HdrImage(arr::AbstractArray{<:Any, 1}, shape)

Construct an [`HdrImage`](@ref) wrapping a matrix obtained from `reshape`.

# Examples

```jldoctest
julia> arr = [RGB( 1.,  2.,  3.), RGB( 4.,  5.,  6.), RGB( 7.,  8.,  9.),
              RGB(10., 11., 12.), RGB(13., 14., 15.), RGB(16., 17., 18.)];

julia> HdrImage(arr, 3, 2)
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


@doc raw"""
    luminosity(image::HdrImage; δ::Float32 = eps(Float32))

Return the average luminosity of `image` as the logaritmic mean of the [`luminosity(::RGB)`](@ref)
``l_i`` of each pixel:

```math
\left< l \right> = 10^{\frac{\sum_i \log_{10}(\delta + l_i)}{N}}
```

The parameter `δ` avoid singularities for ``l_i = 0`` (black pixels).

# Examples

```jldoctest
julia> arr = [RGB( 1.,  2.,  3.), RGB( 4.,  5.,  6.), RGB( 7.,  8.,  9.),
              RGB(10., 11., 12.), RGB(13., 14., 15.), RGB(16., 17., 18.)];

julia> luminosity(HdrImage(arr, 3, 2))
7.706255f0
```
"""
function luminosity(image::HdrImage; δ::Float32 = eps(Float32))
    10^(sum(map(x -> log10(δ + luminosity(x)), image))/length(image))
end

"""
    normalize(image::HdrImage, α::Float32
              ; luminosity::Float32 = average_luminosity(image))

Normalize the image for a given luminosity.

If the `luminosity` parameter is not specified, the image will be normalized according to
the result of [`luminosity(::HdrImage; ::Float32)`](@ref).

# Examples

```jldoctest
julia> arr = [RGB( 1.,  2.,  3.), RGB( 4.,  5.,  6.), RGB( 7.,  8.,  9.),
              RGB(10., 11., 12.), RGB(13., 14., 15.), RGB(16., 17., 18.)];

julia> normalize(HdrImage(arr, 3, 2), 1f0)
3x2 HdrImage:
 (0.12976472 0.25952944 0.38929415)  (1.2976472 1.4274119 1.5571766)
 (0.5190589 0.6488236 0.7785883)     (1.6869414 1.8167061 1.9464709)
 (0.90835303 1.0381178 1.1678824)    (2.0762355 2.2060003 2.335765)
```
"""
function normalize(image::HdrImage, α::Float32; luminosity::Float32 = luminosity(image))
    HdrImage([α / luminosity * pix for pix ∈ image], size(image))
end

"""
    clamp(image::HdrImage)

Adjust the color levels of the brightest pixels in `image`, by applying the [`clamp(::RGB)`](@ref)
function to each pixel.

# Examples

```jldoctest
julia> arr = [RGB( 1.,  2.,  3.), RGB( 4.,  5.,  6.), RGB( 7.,  8.,  9.),
              RGB(10., 11., 12.), RGB(13., 14., 15.), RGB(16., 17., 18.)];

julia> clamp(HdrImage(arr, 3, 2))
3x2 HdrImage:
 (0.5 0.6666667 0.75)        (0.90909094 0.9166667 0.9230769)
 (0.8 0.8333333 0.85714287)  (0.9285714 0.93333334 0.9375)
 (0.875 0.8888889 0.9)       (0.9411765 0.9444444 0.94736844)
```
"""
clamp(image::HdrImage) = HdrImage(clamp.(image))

"""
    γ_correction(image::HdrImage, γ::Float32)

Compute the γ correction of `image`, by applying the [`γ_correction(::RGB, ::Float32)`](@ref)
function to each pixel.

Before calling this function, you should apply a tone-mapping algorithm to the image and be sure that
the R, G, and B values of the colors in the image are all in the range ``[0, 1]``. Use
[`normalize(::HdrImage, ::Float32; ::Float32)`](@ref) and [`clamp(image::HdrImage)`](@ref) to do this.

# Examples

```jldoctest
julia> arr = [RGB( 1.,  2.,  3.), RGB( 4.,  5.,  6.), RGB( 7.,  8.,  9.),
              RGB(10., 11., 12.), RGB(13., 14., 15.), RGB(16., 17., 18.)];

julia> image = normalize(HdrImage(arr, 3, 2), 1f0) |> clamp

julia> γ_correction(image, 1f0)
3x2 HdrImage:
 (0.11485995 0.20605269 0.28021002)  (0.5647722 0.58803856 0.6089437)
 (0.34169766 0.393507 0.43775633)    (0.6278296 0.64497536 0.660611)
 (0.47598794 0.5093512 0.53872037)   (0.67492735 0.6880849 0.7002187)

julia> γ_correction(image, 0.8f0)
3x2 HdrImage:
 (0.06686684 0.13882665 0.20387058)  (0.48960024 0.51494074 0.53792465)
 (0.26124772 0.31166682 0.35607424)  (0.558859 0.57800144 0.5955692)
 (0.39536202 0.43030033 0.4615346)   (0.6117462 0.6266897 0.64053386)

julia> γ_correction(image, 2.4f0)
3x2 HdrImage:
 (0.40588558 0.5177947 0.58855206)  (0.7881591 0.8015287 0.8132807)
 (0.63926977 0.6780008 0.7087834)   (0.82369685 0.83299613 0.8413514)
 (0.73394746 0.7549599 0.77280176)  (0.8489011 0.8557578 0.86201346)
```
"""
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
