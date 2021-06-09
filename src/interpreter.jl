# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Interpreter for input files


#################
# SourceLocation


Base.@kwdef struct SourceLocation
    file_name::String = ""
    line_num::Int = 0
    col_num::Int = 0
end

function Base.show(io::IO, ::MIME"text/plain", loc::SourceLocation)
    print(io, loc.file_name, ":", loc.line_num, ":", loc.col_num)
end

function Base.print(io::IO, loc::SourceLocation)
    print(io, loc.file_name, ":", loc.line_num, ":", loc.col_num)
end



#############
# Exceptions


abstract type ParserError <: Exception end

struct GrammarError <: ParserError 
    location::SourceLocation
    line::AbstractString
end

function Base.showerror(io::IO, e::ParserError)
    print(io, typeof(e), " at ", e.location, ":\n\t", e.line)
end

