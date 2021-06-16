# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# SourceLocation struct for file position


"""
    SourceLocation

Represents a position in a file at a certain line and column.

# Fields

- `file_name::String`: the input file name
- `line_num::Int`: line position
- `col_num::Int`: column position
"""
Base.@kwdef mutable struct SourceLocation
    file_name::String = ""
    line_num::Int = 1
    col_num::Int = 0
end

@doc """
    SourceLocation(file_name::String, line_num::Int, col_num::Int)

Constructor for a [`SourceLocation`](@ref) instance.
""" SourceLocation(::String, ::Int, ::Int)

@doc """
    SourceLocation(; file_name::String = "", line_num::Int = 1, col_num::Int = 0)

Constructor for a [`SourceLocation`](@ref) instance.
""" SourceLocation(; ::String, ::Int, ::Int)

function Base.show(io::IO, ::MIME"text/plain", loc::SourceLocation)
    print(io, abspath(loc.file_name), ":", loc.line_num, ":", loc.col_num)
end

function Base.print(io::IO, loc::SourceLocation)
    print(io, abspath(loc.file_name), ":", loc.line_num, ":", loc.col_num)
end

function Base.copy(loc::SourceLocation)
    SourceLocation(loc.file_name, loc.line_num, loc.col_num)
end
