# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Token implementation


"""
    Keyword

Type wrapping a `Symbol` representing a command or type in a SceneLang script.

# Fields

- `value::Symbol`: the value of the token
"""
struct Keyword
    value::Symbol
end

@enum Command begin
    USING
    SET
    UNSET
    SPAWN
    DUMP
    #construction commands
    LOAD
    ROTATE
    TRANSLATE
    SCALE
    UNITE
    INTERSECT
    DIFF
    FUSE
    TIME
end

@doc """
    Command

Enum type listing all commands of SceneLang.

# Instances

$(join( "- `" .* repr.(instances(Command)) .* "`", "\n"))
""" Command

@enum LiteralType begin
    ColorType
    PointType
    ListType
    TransformationType
    MaterialType
    BrdfType
    PigmentType
    ShapeType
    LightType
    ImageType
    RendererType
    CameraType
    PcgType
    TracerType
end

@doc """
    LiteralType

Enum type listing all main types of SceneLang.

# Instances

$(join( "- `" .* repr.(instances(LiteralType)) .* "`", "\n"))
""" LiteralType

"""
    Identifier

Type wrapping a `Symbol` representing an identifier in a SceneLang script.

# Fields

- `value::Symbol`: the value of the token
"""
struct Identifier
    value::Symbol
end

"""
    LiteralString

Type wrapping a `String` representing a literal string in a SceneLang script.

# Fields

- `value::String`: the value of the token
"""
struct LiteralString
    value::String
end

"""
    LiteralNumber

Type wrapping a `Float32` representing a floating-point number in a SceneLang script.

# Fields

- `value::Float32`: the value of the token
"""
struct LiteralNumber
    value::Float32
end

"""
    LiteralSymbol

Type wrapping a `Symbol` representing a symbol in a SceneLang script.

# Fields

- `value::Symbol`: the value of the token
"""
struct LiteralSymbol
    value::Symbol
end

"""
    MathExpression

Type wrapping a `Expr` representing a mathematical expression in a SceneLang script.

# Fields

- `value::Expr`: the value of the token
"""
struct MathExpression
    value::Expr
end

"""
    StopToken

Convenience empty type to help identify the end of a SceneLang script.

# Fields

- `value::Nothing`: the value of the token
"""
struct StopToken
    value::Nothing

    function StopToken()
        new(nothing)
    end
end

"""
    TokenValue

Union of all types that can be used as token values while interpreting a SceneLang script.

# Types

- [`Keyword`](@ref)
- [`Identifier`](@ref)
- [`LiteralString`](@ref)
- [`LiteralNumber`](@ref)
- [`LiteralSymbol`](@ref)
- [`StopToken`](@ref)

"""
const TokenValue = Union{Keyword, Command, LiteralType, Identifier, MathExpression, LiteralString, LiteralNumber, LiteralSymbol, StopToken}

"""
    Token{T <: TokenValue}

Type representing a language token of a SceneLang script.

# Fields

- `loc::SourceLocation`: a [`SourceLocation`](@ref) representing the position in the script at which the token starts,
- `value::T`: a [`TokenValue`](@ref) representing the value of the token (see [`TokenValue`](@ref))
- `length::Int`: length of the input token.
"""
struct Token{T <: TokenValue}
    loc::SourceLocation
    value::T
    length::Int
end
