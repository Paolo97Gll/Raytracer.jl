# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Interpreter exceptions


"""
    InterpreterException <: Exception

Abstract type for all SceneLang interpreter errors.

See also: [`GrammarException`](@ref)
"""
abstract type InterpreterException <: Exception end


"""
    GrammarException <: InterpreterException

An [`InterpreterException`](@ref) representing an error in the SceneLang lexer.

# Fields

- `location::SourceLocation`: location of the error
- `msg::AbstractString`: descriptive error message
- `len::Int`: how many characters are involved in the error
"""
struct GrammarException <: InterpreterException
    location::SourceLocation
    msg::AbstractString
    len::Int
end

"""
    GrammarException(location::SourceLocation, msg::AbstractString)

Construct an instance of [`GrammarException`](@ref) with `len = 1`.
"""
function GrammarException(location::SourceLocation, msg::AbstractString)
    GrammarException(location, msg, 1)
end

function Base.showerror(io::IO, e::InterpreterException)
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

function Base.showerror(io::IO, e::InterpreterException, bt; backtrace = false)
    try
        showerror(io, e)
    finally
        nothing
    end
end
