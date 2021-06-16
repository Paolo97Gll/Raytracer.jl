# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Token implementation


@enum Keyword begin
    SPAWN = 1
    DESPAWN
end

@doc """
    Keyword

Enum type listing all keywords of SceneLang.

# Instances

$(join( "- `" .* repr.(instances(Keyword)) .* "`", "\n"))
""" Keyword

"""
    Identifier

Type wrapping a `Symbol` representing an identifier in a SceneLang script.
"""
struct Identifier
    name::Symbol
end

"""
    LiteralString

Type wrapping a `String` representing a literal string in a SceneLang script.
"""
struct LiteralString
    value::String
end

"""
    LiteralNumber

Type wrapping a `Float32` representing a floating-point number in a SceneLang script.
"""
struct LiteralNumber
    value::Float32
end

"""
    StopToken

Convenience empty type to help identify the end of a SceneLang script.
"""
struct StopToken end

"""
    TokenValue

Union of all types that can be used as token values while interpreting a SceneLang script.

# Types

- [`LiteralNumber`](@ref)
- [`LiteralString`](@ref)
- [`Keyword`](@ref)
- [`Identifier`](@ref)
- `Symbol`
- [`StopToken`](@ref)

"""
const TokenValue = Union{LiteralNumber, LiteralString, Keyword, Identifier, Symbol, StopToken}

"""
    Token

Type representing a language token of a SceneLang script.

# Fields

- `loc::SourceLocation`: representing the position in the script at which the token starts,
- `value::TokenValue`: representing the value of the token (see [`TokenValue`](@ref))

"""
struct Token
    loc::SourceLocation
    value::TokenValue
end
