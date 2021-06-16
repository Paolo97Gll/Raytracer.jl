# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# InputStream struct for reading SceneLang scripts


"""
    InputStream

Type wrapping the `IOStream` from the source code of a SceneLang script.

# Fields

- `stream::IOStream`: IO stream from the source code
- `location::SourceLocation`: keeps track of the reading position in the source file
- `saved_char::Union{Char, Nothing}`: stores a character from [`unread_char!`](@ref) or nothing
- `saved_location::SourceLocation`: the previous reading position
- `tabulations::Int`: how many columns a `<tab>` charachter is worth

"""
mutable struct InputStream
    stream::IOStream
    location::SourceLocation
    saved_char::Union{Char, Nothing}
    saved_location::SourceLocation
    tabulations::Int

    """
        InputStream(stream, file_name; tabulations = 8)

    Construct an instance of [`InputStream`](@ref).
    """
    function InputStream(stream::IOStream, file_name::String; tabulations::Int = 8)
        loc = SourceLocation(file_name=file_name)
        new(stream, loc, nothing, loc, tabulations)
    end
end

function Base.iterate(stream::InputStream, state::Int = 1)
    isa((token = read_token(stream)).value, StopToken) ? nothing : (token, state + 1)
end

Base.IteratorSize(::Type{InputStream}) = Base.SizeUnknown()

"""
    open_stream(f, file_name; tabulations = 8)

Open read-only a file named `file_name` as an [`InputStream`](@ref) and apply `f` to it.
"""
function open_stream(f::Function, file_name::String; tabulations::Int = 8)
    open(file_name, "r") do io
        InputStream(io, file_name, tabulations=tabulations) |> f
    end
end

"""
    eof(stream::InputStream)

Check if the stream has reached the end-of-file.
"""
Base.eof(stream::InputStream) = eof(stream.stream)
