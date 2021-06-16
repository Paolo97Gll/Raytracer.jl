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
const IdTable = Dict{Type{<:TokenValue}, Dict{Symbol, Token{V} where {V}}}

const TableOrNot = Union{IdTable, Nothing}
const TracerOrNot = Union{ImageTracer, Nothing}
const RendererOrNot = Union{Renderer, Nothing}

mutable struct Scene
    variables::TableOrNot
	image_tracer::TracerOrNot
	renderer::RendererOrNot
end

function Scene(; variables::TableOrNot = nothing, image_tracer::TracerOrNot = nothing, renderer::RendererOrNot = nothing)
	Scene(variables, image_tracer, renderer)
end

function Scene(variables::Vector{Pair{Type{<:TokenValue}, Vector{Pair{Symbol, Token}}}} ; image_tracer::TracerOrNot = nothing, renderer::RendererOrNot = nothing)
	variables =  Dict(zip(first.(variables), (Dict(last(pair)) for pair ∈ variables)))
	Scene(variables, image_tracer, renderer)
end

"""
    expect_keyword(stream::InputStream, keywords_list::Vector{Keyword})

Read a token from an [`InputStream`](@ref) and check that it is a [`Keyword`](@ref) in `keywords_list`.
"""
function expect_keyword(stream::InputStream, keywords_list::Vector{Keyword})
    token = read_token(stream)
    isa(token.value, Keyword) || throw(GrammarException(stream.location,
                                                        "Expected a keyword instead of '$(typeof(token.value.value))'\nValid keywords: $(join(keywords_list, ", "))",
                                                        token.length))
    token.value.value ∈ keywords_list || throw(GrammarException(stream.location,
                                                                "Invalid '$(token.value.value)' keyword, expecting: $(join(keywords_list, ", "))",
                                                                token.length))
    token.value.value
end

"""
    expect_identifier(stream::InputStream)

Read a token from an [`InputStream`](@ref) and check that it is an [`Identifier`](@ref).
"""
function expect_identifier(stream::InputStream)
    token = read_token(stream)
    isa(token.value, Identifier) || throw(GrammarException(stream.location,
                                                           "Got '$(typeof(token.value.value))' instead of an identifier",
                                                           token.length))
    token.value.value
end

"""
    expect_string(stream::InputStream, vars::IdTable)

Read a token from an [`InputStream`](@ref) and check that it is either a [`LiteralString`](@ref) or a variable in [`IdTable`](@ref).
"""
function expect_string(stream::InputStream, vars::IdTable)
    token = read_token(stream)
    isa(token.value, LiteralString) && return token.value.value
    isa(token.value, Identifier) || throw(GrammarException(stream.location,
                                                           "Got '$(typeof(token.value.value))' instead of 'String'",
                                                           token.length))
    var_name = token.value.value
    if !haskey(vars[LiteralString], var_name) 
        (type = findfirst(type -> haskey(vars[type], var_name), keys(vars))) |> isnothing || throw(GrammarException(stream.location, "Variable '$var_name' is a '$type': expected 'LiteralString'"))
        throw(GrammarException(stream.location, "Undefined variable '$var_name'", token.length))
    end
    vars[LiteralString][var_name].value
end

"""
    expect_number(stream::InputStream, vars::IdTable)

Read a token from an [`InputStream`](@ref) and check that it is either a [`LiteralNumber`](@ref) or a variable in [`IdTable`](@ref).
"""
function expect_number(stream::InputStream, vars::IdTable)
    token = read_token(stream)
    isa(token.value, LiteralNumber) && return token.value.value
    isa(token.value, Identifier) || throw(GrammarException(stream.location,
                                                           "Got '$(typeof(token.value.value))' instead of 'Float32'",
                                                           token.length))
    var_name = token.value.value
    if !haskey(vars[LiteralNumber], var_name) 
        (type = findfirst(type -> haskey(vars[type], var_name), keys(vars))) |> isnothing || throw(GrammarException(stream.location, "Variable '$var_name' is a '$type': expected 'LiteralNumber'"))
        throw(GrammarException(stream.location, "Undefined variable '$var_name'", token.length))
    end
    vars[LiteralNumber][var_name].value
end
