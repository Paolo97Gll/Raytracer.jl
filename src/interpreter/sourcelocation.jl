# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

#################
# SourceLocation

"""
    SourceLocation

Represents a position in a file at a certain line and column.
"""
Base.@kwdef mutable struct SourceLocation
    file_name::String = ""
    line_num::Int = 1
    col_num::Int = 0
end

function Base.show(io::IO, ::MIME"text/plain", loc::SourceLocation)
    print(io, joinpath(".", relpath(loc.file_name)), ":", loc.line_num, ":", loc.col_num)
end

function Base.print(io::IO, loc::SourceLocation)
    print(io, joinpath(".", relpath(loc.file_name)), ":", loc.line_num, ":", loc.col_num)
end

function Base.copy(loc::SourceLocation)
    SourceLocation(loc.file_name, loc.line_num, loc.col_num)
end

