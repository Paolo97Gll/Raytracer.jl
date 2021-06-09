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


########
# Token

# @enum TokenEnum begin
#     LiteralNumber
#     LiteralString
#     Keyword
#     Identifier
#     SymbolToken
#     StopToken
# end

@enum Keyword
    somekeyword
end

# const ValueUnion = Union{Float32, String, Keyword, Nothing}

# struct Token{TOK}
#     loc::SourceLocation
#     value::ValueUnion
#     function Token{TOK}(loc::SourceLocation, value::ValueUnion) where {TOK}
#         TOK::TokenEnum
#         new{TOK}(loc, value)
#     end
# end

struct Identifier
    name::String
end

struct LiteralString
    value::String
end

struct LiteralNumber
    value::Float32
end

struct SymbolToken
    symbol::Symbol
end

struct StopToken end

const Tokens = Union{LiteralNumber, LiteralString, Keyword, Identifier, SymbolToken, StopToken}

struct Token 
    loc::SourceLocation
    value::Tokens
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


##############
# InputStream


mutable struct InputStream
    stream::IO
    location::SourceLocation
    saved_char::Union{Char, Nothing}
    saved_location::SourceLocation
    tabulations::Int

    function InputStream(stream::IO, file_name::String; tabulations::Int = 8)
        loc = SourceLocation(file_name=file_name)
        new(stream, loc, nothing, loc, tabulations)
    end
end

eof(stream::InputStream) = eof(stream.stream)

"""Update `location` after having read `ch` from the stream"""
function _update_pos!(stream::InputStream, ch::Union{Char, Nothing})
    if isnothing(ch)
        return
    elseif ch == '\n'
        stream.location.line_num += 1
        stream.location.col_num = 1
    elseif ch == '\t'
        stream.location.col_num += stream.tabulations
    else:
        stream.location.col_num += 1
    end
end

"""Read a new character from the stream"""
function read_char!(stream::InputStream)
    if !isnothing(stream.saved_char)
        # Recover the "unread" character and return it
        ch = stream.saved_char
        stream.saved_char = nothing
    else:
        # Read a new character from the stream
        ch = eof(stream) ? nothing : read(stream.stream, Char)
    end

    stream.saved_location = stream.location
    _update_pos!(stream, ch)

    return ch
end

"""Push a character back to the stream"""
function unread_char!(stream::InputStream, ch::Char):
    @assert isnothing(stream.saved_char)
    stream.saved_char = ch
    stream.location = stream.saved_location
end

"""Keep reading characters until a non-whitespace character is found"""
function skip_whitespaces_and_comments(stream::InputStream):
    ch = readchar!(stream)
    while isspace(ch) || ch == '#'
        ch == '#' && while read_char!(stream) in ['\n', '\r'] || isnothing
        ch = readchar!(stream)
        isnothing(ch) && return
    end

    # Put the non-whitespace character back
    unread_char!(stream, ch)
end