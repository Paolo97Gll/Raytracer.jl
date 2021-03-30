# This file implement the structure HdrImage, which is used to represent an HDR image
#
# Current implementation info:
# - ITERATIONS. Since an HdrImage type is a wrapper struct around a Matrix, iterating
#   on an image means iterating on the underlying Matrix, and in this way we'll implement.
# - BROADCASTING. Same consideration made for the iterations.
# - IO. Utilities for various IO operations, such as printing or writing into
#   a stream.
# - OTHER. Other usefull utilities.
#
# More informations are reported above the single implementation.


##################
# MAIN STRUCTURE #
##################


"""
    HdrImage{T}

Wrapper of a `Matrix` of elements of type `T`, used to represent an image in hdr format.
"""
struct HdrImage{T}
    pixel_matrix::Matrix{T}
end


"""
    HdrImage{T}(img_width, img_height)
    HdrImage(::Type{T}, img_width, img_height)

Construct an `HdrImage` wrapping a zero-initialized matrix of size `(img_width, img_height)`.

# Examples
```jldoctest
julia> a = HdrImage(RGB{Float64}, 3, 2)
3x2 HdrImage{RGB{Float64}}
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
```
"""
@inline function HdrImage{T}(img_width::Integer, img_height::Integer) where {T}
    HdrImage{T}(zeros(T, img_width, img_height))
end
@inline function HdrImage(::Type{T}, img_width::Integer, img_height::Integer) where {T}
    HdrImage{T}(img_width, img_height)
end


"""
    HdrImage(img_width, img_height)

Construct an `HdrImage{RGB{Float32}}` wrapping a zero-initialized matrix of size `(img_width, img_height)`.

# Examples
```jldoctest
julia> a = HdrImage(3, 2)
3x2 HdrImage{RGB{Float32}}
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
 (0.0 0.0 0.0)  (0.0 0.0 0.0)
```
"""
@inline function HdrImage(img_width::Integer, img_height::Integer)
    HdrImage{RGB{Float32}}(img_width, img_height)
end

"""
    HdrImage(arr, img_width, img_height)
    HdrImage(arr, shape)

Construct an `HdrImage{RGB{Float32}}` wrapping a matrix obtained from `reshape`.

# Examples
```jldoctest
julia> arr = [RGB( 1.,  2.,  3.), RGB( 4.,  5.,  6.), RGB( 7.,  8.,  9.), 
              RGB(10., 11., 12.), RGB(13., 14., 15.), RGB(16., 17., 18.)];

julia> a = HdrImage(arr, 3, 2)
3x2 HdrImage{RGB{Float64}}
 (1.0 2.0 3.0)  (10.0 11.0 12.0)
 (4.0 5.0 6.0)  (13.0 14.0 15.0)
 (7.0 8.0 9.0)  (16.0 17.0 18.0)
```
"""
function HdrImage(arr::AbstractArray{<:Any, 1}, im_width::Integer, im_height::Integer)
    HdrImage(reshape(arr, im_width, im_height))
end
function HdrImage(arr::AbstractArray{<:Any, 1}, shape)
    HdrImage(reshape(arr, shape))
end

##############
# ITERATIONS #
##############


length(image::HdrImage) = length(image.pixel_matrix)

firstindex(image::HdrImage) = firstindex(image.pixel_matrix)
firstindex(image::HdrImage, d) = firstindex(image.pixel_matrix, d)

lastindex(image::HdrImage) = lastindex(image.pixel_matrix)
lastindex(image::HdrImage, d) = lastindex(image.pixel_matrix, d)

getindex(image::HdrImage, inds...) = getindex(image.pixel_matrix, inds...)

setindex!(image::HdrImage, value, key) = setindex!(image.pixel_matrix, value, key)
setindex!(image::HdrImage, X, inds...) = setindex!(image.pixel_matrix, X, inds...)

function iterate(image::HdrImage{T}, state = 1) where {T}
    state > lastindex(image) ? nothing : (image[state], state + 1)
end


################
# BROADCASTING #
################


axes(image::HdrImage) = axes(image.pixel_matrix)
axes(image::HdrImage, d) = axes(image.pixel_matrix, d)

broadcastable(image::HdrImage) = image
broadcastable(::Type{<:HdrImage}) = HdrImage

BroadcastStyle(::Type{<:HdrImage}) = Style{HdrImage}()
BroadcastStyle(::Style{HdrImage}, ::BroadcastStyle) = Style{HdrImage}()

@inline function copy(bc::Broadcasted{Style{HdrImage}})
    ElType = combine_eltypes(bc.f, bc.args)
    return HdrImage{ElType}(reshape(collect(convert(Broadcasted{Nothing}, bc)), axes(bc)))
end


######
# IO #
######

# Show in compact mode (i.e. inside a container)
function show(io::IO, image::HdrImage{T}) where {T}
    print_matrix(io, image.pixel_matrix)
end

# Human-readable show (more extended)
function show(io::IO, ::MIME"text/plain", image::HdrImage{T}) where {T}
    println(io, "$(join(map(string, size(image)), "x")) $(typeof(image))")
    print_matrix(io, image.pixel_matrix)
end


# write on stream in PFM format
# need HdrImage broadcasting
"""
    write(io::IO, fe::FE, image)

Write an image to stream in an encoding determined by the [`FE`](@ref).
# Examples
```jldoctest
julia> image = HdrImage(RGB{Float32}[RGB(1.0e1, 2.0e1, 3.0e1) RGB(1.0e2, 2.0e2, 3.0e2)
                                     RGB(4.0e1, 5.0e1, 6.0e1) RGB(4.0e2, 5.0e2, 6.0e2)
                                     RGB(7.0e1, 8.0e1, 9.0e1) RGB(7.0e2, 8.0e2, 9.0e2)]);

julia> io = IOBuffer();

julia> write(io, FE("pfm"), image) # write to stream in pfm format, return number of bytes written
84
```
"""
function write(io::IO, ::FE"pfm", image::HdrImage)
    write(io, transcode(UInt8, "PF\n$(join(size(image)," "))\n$(little_endian ? -1. : 1.)\n"),
        (c for c ∈ image[:, end:-1:begin])...)
end

# parse a string formatted like "$img_width $img_height" and return both values
function _parse_img_size(line::String)
    elements = split(line, ' ')
    correct_length = 2
    (length(elements) == correct_length) || throw(InvalidPfmFileFormat("invalid head in PFM file: image size: expected $correct_length dimensions got $(length(elements))."))
    img_width, img_height = map(_parse_int ∘ string, elements)
end

# verify that the given String is parsable to type and return its parsed value
function _parse_int(str::String)
    DestT = UInt
    try
        parse(DestT, str)
    catch e
        isa(e, ArgumentError) && throw(InvalidPfmFileFormat("invalid head in PFM file: image size: \"$str\" is not parsable to type $DestT."))
        rethrow(e)
    end
end

# verify that the given String is parsable to type Float32 and is equal to ±1.0
# if the parsed value is equal to +1.0 then file endianness is big-endian
# else if it is equal to -1.0 then endianness is little-endian
# return a function that translates from file endianness to host endianness
function _parse_endianness(line::String)
    DestT = Float32
    endian_spec = try
        parse(DestT, line)
    catch e 
        isa(e, ArgumentError) && throw(InvalidPfmFileFormat("invalid head in PFM file: endianness: \"$line\" is not parsable to type $DestT."))
        rethrow(e)
    end

    valid_spec = one(DestT)
    if endian_spec == valid_spec
        return ntoh
    elseif endian_spec == -valid_spec
        return ltoh
    else
        throw(InvalidPfmFileFormat("invalid head in PFM file: endianness: expected ±$valid_spec got $endian_spec."))
    end
end

# read line from stream, return nothing if eof, throw exceptions if read string is not ascii
# and if newlines are not LF conform (it may signal that file corruption occurred
# in file transfer from other systems) else return line
function _read_line(io::IO)
    eof(io) && return nothing
    line = readline(io, keep=true)
    ('\r' ∈ line) && throw(InvalidPfmFileFormat("invalid head in PFM file: newline is not LF conform."))
    isascii(line) || throw(InvalidPfmFileFormat("invalid head in PFM file: found non-ascii line."))
    line
end

# utility function to read the image matrix from file
function _read_matrix(io::IO, DestT::Type, mat_width, mat_height)
    mat = Matrix{DestT}(undef, mat_width, mat_height)
    for i in LinearIndices(mat)
        mat[i] = _read(io, DestT)
    end
    mat
end

# read PFM file from stream
"""
    read(io::IO, fe::FE)

Read an image from stream. The decoding method is determined by the [`FE`](@ref).
"""
function Base.read(io::IO, ::FE"pfm")
    magic = strip(_read_line(io))
    magic == "PF" || throw(InvalidPfmFileFormat("invalid head in PFM file: magic: expected \"PF\" got $magic."))
    img_size_str = _read_line(io)
    img_width, img_height = _parse_img_size(img_size_str)
    endian_str = _read_line(io)
    endian_f = _parse_endianness(endian_str)
    try 
        HdrImage(map(endian_f,_read_matrix(io, RGB{Float32}, img_width, img_height)[:, end:-1:begin]))
    catch e
        isa(e, ArgumentError) && throw(InvalidPfmFileFormat("invalid bytestream in PFM file: corrupted binary data."))
        isa(e, EOFError) && rethrow(InvalidPfmFileFormat("invalid bytestream in PFM file: found less floats than declared in head."))
        rethrow(e)
    end
end


#########
# OTHER #
#########


eltype(::HdrImage{T}) where {T} = T

fill!(image::HdrImage, x) = HdrImage(fill!(image.pixel_matrix, x))

size(image::HdrImage) = size(image.pixel_matrix)