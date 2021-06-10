# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

#############
# Exceptions

"""
    InterpreterError <: Exception

Abstract type for all SceneLang interpreter errors.
"""
abstract type InterpreterError <: Exception end

"""
    GrammarError <: InterpreterError

Type representing an error in the SceneLang lexer.

# Fields

- `location::SourceLocation`: location of the error
- `msg::AbstractString`: descriptive error message
- `len::Int`: how many characters are involved in the error

"""
struct GrammarError <: InterpreterError 
    location::SourceLocation
    msg::AbstractString
    len::Int
end

"""
    GrammarError(location, msg, len = 1)

Construct an instance of [`GrammarError`](@ref).
"""
function GrammarError(location::SourceLocation, msg::AbstractString)
    GrammarError(location, msg, 1)
end

function Base.showerror(io::IO, e::InterpreterError)
    print(io, typeof(e))
    printstyled(io, " @ ", e.location, color=:light_black)
    println(io)
    printstyled(io, e.msg, color=:red) 
    println(io)
    printstyled(io, "source: ", color=:light_black)
    println(io, read_at_line(e.location.file_name, e.location.line_num))
    printstyled(io, " " ^ (e.location.col_num + 6), color=:light_black)
    printstyled(io, "^" ^ e.len, color=:red)
    println(io)
end

function Base.showerror(io::IO, e::InterpreterError, bt; backtrace = false)
    try
        showerror(io, e)
    finally
        nothing
    end
end