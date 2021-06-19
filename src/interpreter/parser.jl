using Base: String, Float32
# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Parser of SceneLang

"""
    IdTable

Alias to `Dict{Type{<:TokenValue}, Dict{Symbol, Token{V} where {V}}}`.

Dictionary with all the variables read from a SceneLang script.
"""
const IdTable = Dict{Type{<:TokenValue}, Dict{Symbol, Token{TokenValue}}}

const TableOrNot = Union{IdTable, Nothing}
const CameraOrNot = Union{Camera, Nothing}
const RendererOrNot = Union{Renderer, Nothing}
const ImageOrNot = Union{HdrImage, Nothing}

mutable struct Scene
    variables::TableOrNot
    world::World
    lights::Lights
    image::ImageOrNot
	camera::CameraOrNot
	renderer::RendererOrNot
end

function Scene(; variables::TableOrNot = nothing, 
                 world::World = World(), 
                 lights::Lights = Lights(), 
                 image::ImageOrNot = nothing, 
                 camera::CameraOrNot = nothing, 
                 renderer::RendererOrNot = nothing)
	Scene(variables, world, lights, image, camera, renderer)
end

function Scene(variables::Vector{Pair{Type{<:TokenValue}, Vector{Pair{Symbol, Token}}}}; 
               world::World = World(), lights::Lights = Lights(), 
               image::ImageOrNot = nothing, 
               camera::CameraOrNot = nothing, 
               renderer::RendererOrNot = nothing)
	variables =  Dict(zip(first.(variables), (Dict(last(pair)) for pair ∈ variables)))
	Scene(variables, world, lights, image, camera, renderer)
end

########
# UTILS

"""
    evaluate_math_expression(token::Token{MathExpression}, vars::IdTable)

Replace all identifiers in the mathematical expression stored in the [`MathExpression`](@ref) token and then evaluate it.
"""
function evaluate_math_expression(token::Token{MathExpression}, vars::IdTable)
    expr = token.value.value
    args = map(expr.args[begin + 1: end]) do arg
        if isa(arg, Symbol)
            if !haskey(vars[LiteralNumber], arg) 
                (type = findfirst(type -> haskey(vars[type], arg), keys(vars))) |> isnothing || 
                    throw(WrongTokenType(token.loc, "Variable '$arg' is a '$type' in 'MathExpression': expected 'LiteralNumber'"))
                throw(UndefinedIdentifier(token.loc, "Undefined variable '$arg' in 'MathExpression'", token.length))
            end
            return vars[arg]
        elseif isa(arg, Expr)
            return evaluate_math_expression(arg, vars)
        else
            return arg
        end
    end
    Expr(expr.head, expr.args[begin], args...) |> eval
end

##############
# EXPECTATION

"""
    expect_keyword(stream::InputStream, keywords_list::Vector{Symbol}Union{NTuple{N, Symbol} where {N}, AbstractVector{Symbol}})

Read a token from an [`InputStream`](@ref) and check that it is a [`Keyword`](@ref) in `keywords_list`.
"""
function expect_keyword(stream::InputStream, keywords_list::Union{NTuple{N, Symbol} where {N}, AbstractVector{Symbol}})
    token = read_token(stream)
    isa(token.value, Keyword) || throw(WrongTokenType(token.loc,
                                                        "Expected a keyword instead of '$(typeof(token.value.value))'\nValid keywords: $(join(keywords_list, ", "))",
                                                        token.length))
    token.value.value ∈ keywords_list || throw(InvalidKeyword(token.loc,
                                                          "Invalid '$(token.value.value)' keyword\nValid keywords: $(join(keywords_list, ", "))",
                                                          token.length))
    token
end

"""
    expect_command(stream::InputStream)

Read a token from an [`InputStream`](@ref) and check that it is a [`Command`](@ref).
"""
function expect_command(stream::InputStream)
    token = read_token(stream)
    isa(token.value, Command) || throw(WrongTokenType(token.loc,
                                                      "Expected a command instead of '$(typeof(token.value.value))'",
                                                      token.length))
    token
end

"""
    expect_command(stream::InputStream, command::Command)

Read a token from an [`InputStream`](@ref) and check that it is a [`Command`](@ref).
"""
function expect_command(stream::InputStream, command::Command)
    token = expect_command(stream)
    token.value == command || throw(InvalidSymbol(token.loc,
                                                  "Invalid command '$(token.value)'\nValid commands: $command",
                                                  token.length))
    token
end

"""
    expect_command(stream::InputStream, commands::Union{NTuple{N, Command} where {N}, AbstractVector{Command}})

Read a token from an [`InputStream`](@ref) and check that it is a [`Command`](@ref).
"""
function expect_command(stream::InputStream, commands::Union{NTuple{N, Command} where {N}, AbstractVector{Command}})
    token = expect_command(stream)
    token.value ∈ commands || throw(InvalidSymbol(token.loc,
                                                  "Invalid command '$(token.value.value)'\nValid commands:\n\t$(join(commands, "\n\t"))",
                                                  token.length))
    token
end

"""
    expect_type(stream::InputStream)

Read a token from an [`InputStream`](@ref) and check that it is a [`LiteralType`](@ref).
"""
function expect_type(stream::InputStream)
    token = read_token(stream)
    isa(token.value, LiteralType) || throw(WrongTokenType(token.loc,
                                                          "Expected a type instead of '$(typeof(token.value.value))'",
                                                          token.length))
    token
end

"""
    expect_type(stream::InputStream, type::LiteralType)

Read a token from an [`InputStream`](@ref) and check that it is a [`LiteralType`](@ref), then check if its value is the given type.
"""
function expect_type(stream::InputStream, type::LiteralType)
    token = expect_type(stream)
    token.value == type || throw(WrongValueType(token.loc, "Expected type '$type', got: '$(token.value)'", token.length))
    token
end

"""
    expect_identifier(stream::InputStream)

Read a token from an [`InputStream`](@ref) and check that it is an [`Identifier`](@ref).
"""
function expect_identifier(stream::InputStream)
    token = read_token(stream)
    isa(token.value, Identifier) || throw(WrongTokenType(token.loc,
                                                           "Got token '$(typeof(token.value))' instead of 'Identifier'",
                                                           token.length))
    token
end

"""
    expect_string(stream::InputStream, vars::IdTable)

Read a token from an [`InputStream`](@ref) and check that it is either a [`LiteralString`](@ref) or a variable in [`IdTable`](@ref).
"""
function expect_string(stream::InputStream, vars::IdTable)
    token = read_token(stream)
    isa(token.value, LiteralString) && return token.value.value
    isa(token.value, Identifier) || throw(WrongTokenType(token.loc,
                                                           "Got token '$(typeof(token.value))' instead of 'LiteralString'",
                                                           token.length))
    var_name = token.value.value
    if !haskey(vars[LiteralString], var_name) 
        (type = findfirst(type -> haskey(vars[type], var_name), keys(vars))) |> isnothing || 
            throw(WrongValueType(token.loc, "Variable '$var_name' is a '$type': expected 'LiteralString'"))
        throw(UndefinedIdentifier(token.loc, "Undefined variable '$var_name'", token.length))
    end
    vars[LiteralString][var_name]
end

"""
    expect_number(stream::InputStream, vars::IdTable)

Read a token from an [`InputStream`](@ref) and check that it is either a [`LiteralNumber`](@ref) or a variable in [`IdTable`](@ref).
"""
function expect_number(stream::InputStream, vars::IdTable)
    token = read_token(stream)
    isa(token.value, LiteralNumber) && return token
    isa(token.value, MathExpression) && return Token(token.loc, LiteralNumber(evaluate_math_expression(token, vars)), token.length)
    isa(token.value, Identifier) || throw(WrongTokenType(token.loc,
                                                           "Got '$(typeof(token.value))' instead of 'LiteralNumber'",
                                                           token.length))
    var_name = token.value.value
    if !haskey(vars[LiteralNumber], var_name) 
        (type = findfirst(type -> haskey(vars[type], var_name), keys(vars))) |> isnothing || 
            throw(WrongValueType(token.loc, "Variable '$var_name' is a '$type': expected 'LiteralNumber'"))
        throw(UndefinedIdentifier(token.loc, "Undefined variable '$var_name'", token.length))
    end
    vars[LiteralNumber][var_name]
end

"""
    expect_symbol(stream::InputStream, symbol::LiteralSymbol)

Read a token from an [`InputStream`](@ref) and check that it is the requested [`LiteralSymbol`](@ref).
"""
function expect_symbol(stream::InputStream, symbol::Symbol)
    token = read_token(stream)
    isa(token.value, LiteralSymbol) || throw(WrongTokenType(token.loc,
                                                            "Expected a symbol instead of '$(typeof(token.value))'\nValid symbol: $symbol",
                                                            token.length))

    token.value.value == symbol || throw(InvalidSymbol(token.loc,
                                                       "Invalid symbol '$(token.value.value)' \nValid symbol: $symbol",
                                                       token.length))
    token
end

"""
    expect_symbol(stream::InputStream, symbols::Union{Tuple{N, Symbol} where {N}, AbstractVector{Symbol}})

Read a token from an [`InputStream`](@ref) and check that it is one of the requested [`LiteralSymbol`](@ref)s.
"""
function expect_symbol(stream::InputStream, symbols::Union{Tuple{N, Symbol} where {N}, AbstractVector{Symbol}})
    token = read_token(stream)
    isa(token.value, LiteralSymbol) || throw(WrongTokenType(token.loc,
                                                            "Expected a symbol instead of '$(typeof(token.value.value))'\nValid symbols:\n\t$(join(symbols, "\n\t"))",
                                                           token.length))

    token.value.value ∈ symbols || throw(InvalidSymbol(token.loc,
                                                       "Invalid symbol '$(token.value.value)'\nValid symbols:\n\t$(join(symbols, "\n\t"))",
                                                    token.length))
    token
end

##########
# PARSING

