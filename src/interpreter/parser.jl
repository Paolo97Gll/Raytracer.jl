# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Parser of SceneLang
"""
    ValueLoc

Stores a Julia value and the source location of its declaration.
"""
struct ValueLoc
    value::Any
    loc::SourceLocation
end

function Base.show(io::IO, valueloc::ValueLoc)
    print(io, valueloc.value)
    printstyled(io, " @ ", valueloc.loc, color = :light_black)
end

function Base.show(io::IO, ::MIME"text/plain", valueloc::ValueLoc)
    print(io, valueloc.value)
    printstyled(io, " @ ", valueloc.loc, color = :light_black)
end

"""
    IdTableKey

Alias for `Union{Type{<:TokenValue}, LiteralType}`. Used as the key type for [`IdTable`](@ref).
"""
const IdTableKey = Union{Type{<:TokenValue}, LiteralType}

"""
    IdTable

Alias to `Dict{IdTableKey, Dict{Symbol, ValueLoc}}`.

Dictionary with all the variables set in a SceneLang script.
Keys represent the equivalent [`TokenValue`](@ref) or [`LiteralType`](@ref) type to the Julia type stored in [`ValueLoc`](@ref).
"""
const IdTable = Dict{IdTableKey, Dict{Symbol, ValueLoc}}

function Base.show(io::IO, table::IdTable)
    show(io, MIME("text/plain"), table)
end

function Base.show(io::IO, ::MIME"text/plain", table::IdTable)
    for (key, subdict) ∈ pairs(table)
        printstyled(io, "#### ", key, " ####", color = :blue, bold = true)
        println()
        for (id, value) ∈ pairs(subdict)
            printstyled(io, id, color = :green)
            println(io, " = ", value)
        end
        println(io)
    end
end

"""
    RendererSettings

Struct containing a renderer type and a `NamedTuple` of the named arguments needed for its construction.

Since a [`Renderer`](@ref) type cannot be directly stored into a [`Scene`](@ref) due to it needing at least the [`World`](@ref) argument,
we can use this struct to store everything else, ready to be constructed.
"""
struct RendererSettings
    type::Type{<:Renderer}
    kwargs::NamedTuple
end

"""
    TracerSettings

Struct containing a `NamedTuple` of the named arguments needed to construct an [`ImageTracer`](@ref).

Since a [`ImageTracer`](@ref) type cannot be directly stored into a [`Scene`](@ref) due to it needing at least the [`Camera`](@ref)
and [`HdrImage`](@ref) arguments, we can use this struct to store everything else, ready to be constructed.
"""
struct TracerSettings
    kwargs::NamedTuple
end

"""
    CameraOrNot

Alias for `Union{Camera, Nothing}`.

See also: [`Scene`](@ref)
"""
const CameraOrNot = Union{Camera, Nothing}
"""
    RendererOrNot

Alias for `Union{RendererSettings, Nothing}`.

See also: [`Scene`](@ref)
"""
const RendererOrNot = Union{RendererSettings, Nothing}
"""
    ImageOrNot

Alias for `Union{HdrImage, Nothing}`.

See also: [`Scene`](@ref)
"""
const ImageOrNot = Union{HdrImage, Nothing}
"""
    TracerOrNot

Alias for `Union{TracerSettings, Nothing}`.

See also: [`Scene`](@ref)
"""
const TracerOrNot = Union{TracerSettings, Nothing}

"""
    Scene

A mutable struct containing all the significant elements of a renderable scene and all the declared variables of the SceneLang script.

# Fields

- `variables::`[`IdTable`](@ref): stores all the variables declared in the script
- `world::`[`World`](@ref): stores all the spawned [`Shape`](@ref)s
- `lights::`[`Lights`](@ref): stores all the spawned [`PointLight`](@ref)s
- `image::`[`ImageOrNot`](@ref): stores either the [`HdrImage`](@ref) to impress or `nothing`
- `camera::`[`CameraOrNot`](@ref): stores either the [`Camera`](@ref) or `nothing`
- `renderer::`[`RendererOrNot`](@ref): stores either the [`RendererSettings`](@ref) for the [`Renderer`](@ref) or `nothing`
- `tracer::`[`TracerOrNot`](@ref): strores either the [`TracerSettings`](@ref) for the [`ImageTracer`](@ref) or `nothing`
- `time`: stores the animation time
"""
mutable struct Scene
    variables::IdTable
    world::World
    lights::Lights
    image::ImageOrNot
	camera::CameraOrNot
	renderer::RendererOrNot
    tracer::TracerOrNot
    time
end

"""
    Scene(; variables::IdTable = IdTable(),
            world::World = World(),
            lights::Lights = Lights(),
            image::ImageOrNot = nothing,
            camera::CameraOrNot = nothing,
            renderer::RendererOrNot = nothing,
            tracer::TracerOrNot = nothing,
            time = 0)


Constructor for a [`Scene`](@ref) instance.
"""
function Scene(; variables::IdTable = IdTable(),
                 world::World = World(),
                 lights::Lights = Lights(),
                 image::ImageOrNot = nothing,
                 camera::CameraOrNot = nothing,
                 renderer::RendererOrNot = nothing,
                 tracer::TracerOrNot = nothing,
                 time = 0)
	Scene(variables, world, lights, image, camera, renderer, tracer, time)
end

"""
    Scene(variables::Vector{Pair{Type{<:TokenValue}, Vector{Pair{Symbol, Token}}}};
          world::World = World(),
          lights::Lights = Lights(),
          image::ImageOrNot = nothing,
          camera::CameraOrNot = nothing,
          renderer::RendererOrNot = nothing,
          tracer::TracerOrNot = nothing,
          time = 0)


Constructor for a [`Scene`](@ref) instance.

Slightly more convenient than the default constructor to manually construct in a Julia code.
"""
function Scene(variables::Vector{Pair{Type{<:TokenValue}, Vector{Pair{Symbol, Token}}}};
               world::World = World(), lights::Lights = Lights(),
               image::ImageOrNot = nothing,
               camera::CameraOrNot = nothing,
               renderer::RendererOrNot = nothing,
               tracer::TracerOrNot = nothing,
               time = 0)

	variables =  Dict(zip(first.(variables), (Dict(last(pair)) for pair ∈ variables)))
	Scene(variables, world, lights, image, camera, renderer, tracer, time)
end

function Base.show(io::IO, ::MIME"text/plain", scene::Scene)
    printstyled(io, ".VARIABLES\n\n", color = :magenta, bold= true)
    show(io, scene.variables)
    println(io)

    printstyled(io, ".WORLD\n\n", color = :magenta, bold= true)
    if !isempty(scene.world)
        for (i, shape) ∈ enumerate(scene.world)
            printstyled(io, i, color = :green)
            println(io, ": ", shape)
        end
        println(io)
    end
    println(io)

    printstyled(io, ".LIGHTS\n\n", color = :magenta, bold= true)
    if !isempty(scene.lights)
        for (i, light) ∈ enumerate(scene.lights)
            printstyled(io, i, color = :green)
            println(io, ": ", light)
        end
        println(io)
    end
    println(io)

    printstyled(io, ".IMAGE\n\n", color = :magenta, bold= true)
    if !isnothing(scene.image)
        printstyled(io, "image", color = :green)
        println(io, " = ", scene.image)
        println(io)
    end
    println(io)

    printstyled(io, ".CAMERA\n\n", color = :magenta, bold= true)
    if !isnothing(scene.camera)
        printstyled(io, "camera", color = :green)
        println(io, " = ", scene.camera)
        println(io)
    end
    println(io)

    printstyled(io, ".RENDERER\n\n", color = :magenta, bold= true)
    if !isnothing(scene.renderer)
        printstyled(io, "type", color = :green)
        println(io, " = ", scene.renderer.type)
        if isempty(scene.renderer.kwargs)
            printstyled(io, "default kwargs\n\n", color=:light_black)
        else
            for (kw, value) ∈ pairs(scene.renderer.kwargs)
                printstyled(io, kw, color = :green)
                println(io, " = ", value)
            end
        end
    end

    printstyled(io, ".TRACER\n\n", color = :magenta, bold= true)
    if !isnothing(scene.tracer)
        if isempty(scene.tracer.kwargs)
            printstyled(io, "default kwargs\n\n", color=:light_black)
        else
            for (kw, value) ∈ pairs(scene.tracer.kwargs)
                printstyled(io, kw, color = :green)
                println(io, " = ", value)
            end
        end
    end

    printstyled(io, ".TIME\n\n", color = :magenta, bold= true)
    printstyled(io, "time", color = :green)
    println(io, " = ", scene.time)
    println(io)

end

########
# UTILS

"""
    evaluate_math_expression(token::Token{MathExpression}, scene::Scene)

Replace all identifiers in the mathematical expression stored in the [`MathExpression`](@ref) token and then evaluate it.
"""
function evaluate_math_expression(token::Token{MathExpression}, scene::Scene)
    vars = scene.variables
    expr = token.value.value
    args = map(expr.args[begin + 1: end]) do arg
        if isa(arg, Symbol)
            arg === :TIME && return scene.time
            if !haskey(vars[LiteralNumber], arg)
                (type = findfirst(d -> haskey(d, arg), vars)) |> isnothing ||
                    throw(WrongTokenType(token.loc, "Variable '$arg' is a '$type' in 'MathExpression': expected 'LiteralNumber'\nVariable '$arg' was declared at $(vars[type][arg].loc)", token.length))
                throw(UndefinedIdentifier(token.loc, "Undefined variable '$arg' in 'MathExpression'", token.length))
            end
            return vars[LiteralNumber][arg].value
        elseif isa(arg, Expr)
            return evaluate_math_expression(Token(token.loc, MathExpression(arg), token.length), vars)
        else
            isfinite(arg) ||
                throw(InvalidExpression(token.loc, "'MathExpression' should not return or contain infinite or NaN values.", token.length))
            return arg
        end
    end
    res = try
        Expr(expr.head, expr.args[begin], args...) |> eval
    catch e
        isa(e, ArgumentError) &&
            throw(InvalidExpression(token.loc, "Julia `eval` has thrown an error:\n`$(e.msg)`\nPlease follow the exception instructions or consult Julia documentation", token.length))
        if isa(e, DomainError)
            msg = "DomainError with " * repr( e.val)
            if isdefined(e, :msg)
                msg *= ":\n" * e.msg
            end
            throw(InvalidExpression(token.loc, "Julia `eval` has thrown an error:\n`$(e.msg)`\nPlease follow the exception instructions or consult Julia documentation", token.length))
        end
        rethrow(e)
    end
    isfinite(res) ||
        throw(InvalidExpression(token.loc, "'MathExpression' should not return or contain infinite or NaN values.", token.length))
    res
end

"""
    function generate_kwargs(stream::InputStream, scene::Scene, kw::NamedTuple)

Return a `Dict{Symbol, Any}` as instructed by the given `kw` `NamedTuple`.

The argument `kw` pairs all the keywords a constructor need with the parsing functions they need.
This function parses keywords and/or values until it reaches the end of the constructor.
The arguments may also be positional, but positional arguments must not follow keyword arguments.
If a keyword is used more than once an exception is thrown.
"""
function generate_kwargs(stream::InputStream, scene::Scene, kw::NamedTuple)
    expect_symbol(stream, Symbol("("))
    kwargs = Dict{Symbol, Any}()
    sizehint!(kwargs, length(kw))
    is_positional_allowed = true
    for i ∈ SOneTo(length(kw))
        token = read_token(stream)
        unread_token(stream, token)
        isa(token.value, LiteralSymbol) && (expect_symbol(stream, Symbol(")")); break)
        key = if isa(token.value, Keyword)
            local key = expect_keyword(stream, keys(kw)).value.value
            haskey(kwargs, key) &&
                throw(InvalidKeyword(token.loc, "Argument `$key` has already been defined", token.length))
            is_positional_allowed = false
            key
        elseif is_positional_allowed
            keys(kw)[i]
        else
            throw(InvalidKeyword(token.loc, "Positional arguments cannot follow keyword arguments", token.length))
        end
        value = kw[key](stream, scene)
        push!(kwargs, key => value)
        expect_symbol(stream, (Symbol(","), Symbol(")"))).value.value == Symbol(")") && break
    end
    kwargs
end

"""
    parse_by_identifier(expected_type::IdTableKey, stream::InputStream, table::IdTable)

If the next token is an [`Identifier`](@ref), check that its type is coherent with `expected_type` and return its value.
"""
function parse_by_identifier(expected_type::IdTableKey, stream::InputStream, table::IdTable)
    next_token = read_token(stream)
    unread_token(stream, next_token)
    if !isa(next_token.value, Identifier)
        return nothing
    end
    id_name = next_token.value.value
    haskey(table[expected_type], id_name) && return table[expected_type][id_name].value
    (type = findfirst(d -> haskey(d, id_name), table)) |> isnothing ||
        throw(WrongTokenType(next_token.loc, "Variable '$id_name' is of type '$type': expected '$expected_type'\nVariable '$id_name' was declared at $(table[type][id_name].loc)", next_token.length))
    throw(UndefinedIdentifier(next_token.loc, "Undefined variable '$id_name'", next_token.length))
end

##############
# EXPECTATION

"""
    expect_keyword(stream::InputStream, keyword::Symbol)

Read a token from an [`InputStream`](@ref) and check that it is a given [`Keyword`](@ref).
"""
function expect_keyword(stream::InputStream, keyword::Symbol)
    token = read_token(stream)
    isa(token.value, Keyword) || throw(WrongTokenType(token.loc,
                                                      "Expected a keyword instead of '$(typeof(token.value))'\nValid keyword: $keyword",
                                                      token.length))
    token.value.value == keyword || throw(InvalidKeyword(token.loc,
                                                         "Invalid '$(token.value.value)' keyword\nValid keyword: $keyword",
                                                         token.length))
    token
end

"""
    expect_keyword(stream::InputStream, keywords_list::Union{NTuple{N, Symbol} where {N}, AbstractVector{Symbol}})

Read a token from an [`InputStream`](@ref) and check that it is a [`Keyword`](@ref) in `keywords_list`.
"""
function expect_keyword(stream::InputStream, keywords_list::Union{NTuple{N, Symbol} where {N}, AbstractVector{Symbol}})
    token = read_token(stream)
    isa(token.value, Keyword) || throw(WrongTokenType(token.loc,
                                                      "Expected a keyword instead of '$(typeof(token.value))'\nValid keywords:\n\t$(join(keywords_list, "\n\t"))",
                                                      token.length))
    token.value.value ∈ keywords_list || throw(InvalidKeyword(token.loc,
                                                              "Invalid '$(token.value.value)' keyword\nValid keywords:\n\t$(join(keywords_list, "\n\t"))",
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
                                                      "Expected a command instead of '$(typeof(token.value))'",
                                                      token.length))
    token
end

"""
    expect_command(stream::InputStream, command::Command)

Read a token from an [`InputStream`](@ref) and check that it is a given [`Command`](@ref).
"""
function expect_command(stream::InputStream, command::Command)
    token = expect_command(stream)
    token.value == command || throw(InvalidCommand(token.loc,
                                                  "Invalid command '$(token.value)'\nValid command: $command",
                                                  token.length))
    token
end

"""
    expect_command(stream::InputStream, commands::Union{NTuple{N, Command} where {N}, AbstractVector{Command}})

Read a token from an [`InputStream`](@ref) and check that it is a [`Command`](@ref) in the given `commands`.
"""
function expect_command(stream::InputStream, commands::Union{NTuple{N, Command} where {N}, AbstractVector{Command}})
    token = expect_command(stream)
    token.value ∈ commands || throw(InvalidCommand(token.loc,
                                                  "Invalid command '$(token.value)'\nValid commands:\n\t$(join(commands, "\n\t"))",
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
                                                          "Expected a type instead of '$(typeof(token.value))'",
                                                          token.length))
    token
end

"""
    expect_type(stream::InputStream, type::LiteralType)

Read a token from an [`InputStream`](@ref) and check that it is a given [`LiteralType`](@ref).
"""
function expect_type(stream::InputStream, type::LiteralType)
    token = expect_type(stream)
    token.value == type || throw(WrongValueType(token.loc, "Expected type '$type', got: '$(token.value)'", token.length))
    token
end

"""
    expect_type(stream::InputStream, types::Union{NTuple{N, LiteralType} where {N}, AbstractVector{LiteralType}})

Read a token from an [`InputStream`](@ref) and check that it is a [`LiteralType`](@ref) in the given `types`.
"""
function expect_type(stream::InputStream, types::Union{NTuple{N, LiteralType} where {N}, AbstractVector{LiteralType}})
    token = expect_type(stream)
    token.value ∈ types || throw(WrongValueType(token.loc,
                                               "Invalid type '$(token.value)'\nValid types:\n\t$(join(types, "\n\t"))",
                                               token.length))
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
    expect_string(stream::InputStream)

Read a token from an [`InputStream`](@ref) and check that it is a [`LiteralString`](@ref).
"""
function expect_string(stream::InputStream)
    token = read_token(stream)
    isa(token.value, LiteralString) && return token
    throw(WrongTokenType(token.loc,"Got token '$(typeof(token.value))' instead of 'LiteralString'", token.length))
end

"""
    expect_number(stream::InputStream, scene::Scene)

Read a token from an [`InputStream`](@ref) and check that it is either a [`LiteralNumber`](@ref) or a valid [`MathExpression`](@ref).
"""
function expect_number(stream::InputStream, scene::Scene)
    vars =scene.variables
    token = read_token(stream)
    isa(token.value, LiteralNumber) && return token
    isa(token.value, MathExpression) && return Token(token.loc, LiteralNumber(evaluate_math_expression(token, vars)), token.length)
    token.value == TIME && return Token(token.loc, scene.time, token.length)
    throw(WrongTokenType(token.loc,
                         "Got '$(typeof(token.value))' instead of 'LiteralNumber'",
                         token.length))
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
                                                            "Expected a symbol instead of '$(typeof(token.value))'\nValid symbols:\n\t$(join(symbols, "\n\t"))",
                                                            token.length))

    token.value.value ∈ symbols || throw(InvalidSymbol(token.loc,
                                                       "Invalid symbol '$(token.value.value)'\nValid symbols:\n\t$(join(symbols, "\n\t"))",
                                                       token.length))
    token
end

##########
# PARSING

###############
## CONSTRUCTORS

"""
    parse_constructor(stream::InputStream, scene::Scene)

Return a `Tuple{Any, IdTableKey}` containing the result of the construction and its type.

If the expression from the `stream` is not a valid constructor an exception is thrown.
"""
function parse_constructor(stream::InputStream, scene::Scene)
    table =scene.variables
    next_token = read_token(stream)
    unread_token(stream, next_token)
    next_val = next_token.value
    if isa(next_val, Command)
        next_val == TIME &&
            return(scene.time, LiteralNumber)
        next_val ∈ (ROTATE, TRANSLATE, SCALE) &&
            return (parse_transformation_from_command(stream, scene), TransformationType)
        next_val == LOAD &&
            return (parse_image_from_command(stream, scene), ImageType)
        next_val ∈ (UNITE, INTERSECT, DIFF, FUSE) &&
            return (parse_shape_from_command(stream, scene), ShapeType)
        throw(InvalidCommand(next_token.loc, "Command '$next_val' is not a valid construction command."))
    elseif isa(next_val, LiteralType)
        for (type, parser) ∈ (ListType           => parse_list,
                              ColorType          => parse_color,
                              PointType          => parse_point,
                              TransformationType => parse_transformation,
                              MaterialType       => parse_material,
                              BrdfType           => parse_brdf,
                              PigmentType        => parse_pigment,
                              ShapeType          => parse_shape,
                              LightType          => parse_light,
                              ImageType          => parse_image,
                              RendererType       => parse_renderer_settings,
                              CameraType         => parse_camera,
                              PcgType            => parse_pcg,
                              TracerType         => parse_tracer_settings)
            next_val == type || continue
            return (parser(stream, scene), type)
        end
        @assert false "@ $(next_token.loc): LiteralType $next_val has no named constructor."
    elseif isa(next_val, LiteralNumber) || isa(next_val, MathExpression)
        return (parse_float(stream, scene), LiteralNumber)
    elseif isa(next_val, LiteralSymbol)
        next_sym = next_val.value
        next_sym == Symbol("<") && return (parse_color(stream, scene), ColorType)
        next_sym == Symbol("{") && return (parse_point(stream, scene), PointType)
        next_sym == Symbol("[") && return (parse_list(stream, scene),  ListType)
        throw(InvalidSymbol(token.loc,
                            "Invalid symbol '$(token.value.value)'\nValid symbols:\n\t$(join((Symbol("<"), Symbol("{"), Symbol("["), Symbol("\$")), "\n\t"))",
                            token.length))
    elseif isa(next_val, LiteralString)
        return (parse_string(stream, scene), LiteralString)
    elseif isa(next_val, Identifier)
        throw(WrongTokenType("Cannot construct from identifier."))
    else
        throw(WrongTokenType("Token '$next_val' is not a valid construction token."))
    end
end

"""
    parse_string(stream::InputStream, scene::Scene)

Return a `String` value from either a [`LiteralString`](@ref) constructor or an appropriate [`Identifier`](@ref).
"""
function parse_string(stream::InputStream, scene::Scene)
table = scene.variables
    (from_id = parse_by_identifier(LiteralString, stream, table)) |> isnothing || (read_token(stream); return from_id)
    expect_string(stream).value.value
end

"""
    parse_int(stream::InputStream, scene::Scene)

Return a `Int` value from either a [`LiteralNumber`](@ref) constructor or an appropriate [`Identifier`](@ref).

If the `Float32` number is not exactly representing an integer number an exception is thrown.
"""
function parse_int(stream::InputStream, scene::Scene)
    table = scene.variables
    n_token = if parse_by_identifier(LiteralNumber, stream, table) |> isnothing
        expect_number(stream, scene)
    else
        read_token(stream)::Token{Identifier}
    end

    try
        convert(Int, n_token.value.value)
    catch e
        isa(e, InexactError) || rethrow(e)
        throw(WrongValueType(n_token.loc,"The given number is not convertible to an integer since it is not round",n_token.length))
    end
end

"""
    parse_float(stream::InputStream, scene::Scene)

Return a `Float32` value from either a [`LiteralNumber`](@ref) constructor or an appropriate [`Identifier`](@ref).
"""
function parse_float(stream::InputStream, scene::Scene)
    table = scene.variables
    (from_id = parse_by_identifier(LiteralNumber, stream, table)) |> isnothing || (read_token(stream); return from_id)
    expect_number(stream, scene).value.value
end

"""
    parse_list(stream::InputStream, scene::Scene)

Return a `Vector{Float32}` value from either a named constructor, a symbolic constructor or an appropriate [`Identifier`](@ref).
"""
function parse_list(stream::InputStream, scene::Scene)
    table = scene.variables
    (from_id = parse_by_identifier(ListType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    next_token = read_token(stream)
    unread_token(stream, next_token)
    delim = if isa(next_token.value, LiteralType)
        expect_type(stream, ListType)
        expect_symbol(stream, Symbol("("))
        Symbol(")")
    elseif isa(next_token.value, LiteralSymbol)
        expect_symbol(stream, Symbol("["))
        Symbol("]")
    else
        throw(WrongTokenType(next_token.loc,"Expected either a 'LiteralType' or a 'LiteralSymbol', got '$(typeof(next_token.value))'",next_token.length))
    end
    vec = Vector{Float32}()
    sizehint!(vec, 16) # I do not expect the users to define any list longer than 16, even if they have the ability to
    push!(vec, expect_number(stream, scene))
    while expect_symbol(stream, (Symbol(","), delim)).value.value == Symbol(",")
        push!(vec, expect_number(stream, scene))
    end
    vec
end

"""
    parse_list(stream::InputStream, scene::Scene, list_length::Int)

Return a `SVector{list_length, Float32}` value from either a named constructor, a symbolic constructor or an appropriate [`Identifier`](@ref).

If the list is not exactly `list_length` long an exception will be thrown.
"""
function parse_list(stream::InputStream, scene::Scene, list_length::Int)
    @assert list_length >= 1 "list must have size of at least 1"
    if (from_id = parse_by_identifier(ListType, stream, table)) |> !isnothing
        token = read_token(stream)
        if length(from_id) != list_length
            id_name = token.value.value
            throw(InvalidSize(token.loc, "Variable '$(id_name)' stores a list of length $(length(from_id)): expected length $list_length.\nVariable '$id_name' was declared at $(table[ListType][id_name].loc)", token.length))
        end
        return from_id
    end
    table = scene.variables

    next_token = read_token(stream)
    unread_token(stream, next_token)
    delim = if isa(next_token.value, LiteralType)
        expect_type(stream, ListType)
        expect_symbol(stream, Symbol("("))
        Symbol(")")
    elseif isa(next_token.value, LiteralSymbol)
        expect_symbol(stream, Symbol("["))
        Symbol("]")
    else
        throw(WrongTokenType(next_token.loc,"Expected either a 'LiteralType' or a 'LiteralSymbol', got '$(typeof(next_token.value))'",next_token.length))
    end

    vec = SVector{list_length, Float32}([expect_number(stream, scene).value.value,
                                         ((expect_symbol(stream, Symbol(",")); expect_number(stream, scene).value.value) for _ ∈ SOneTo(list_length - 1))...
                                        ])

    expect_symbol(stream, delim)

    vec
end

"""
    parse_point(stream::InputStream, scene::Scene)

Return a [`Point`](@ref) value from either a named constructor, a symbolic constructor or an appropriate [`Identifier`](@ref).

If the constructor has not exactly three arguments an exception will be thrown.
"""
function parse_point(stream::InputStream, scene::Scene)
    table = scene.variables
    (from_id = parse_by_identifier(PointType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    next_token = read_token(stream)
    unread_token(stream, next_token)
    if isa(next_token.value, LiteralType)
        expect_type(stream, PointType)
        kw = (; X = parse_float, Y = parse_float, Z = parse_float)

        kwargs = generate_kwargs(stream, scene, kw)
        x = get(kwargs, :X, 0)
        y = get(kwargs, :Y, 0)
        z = get(kwargs, :Z, 0)
    elseif isa(next_token.value, LiteralSymbol)
        expect_symbol(stream, Symbol("{"))
        x = expect_number(stream, scene).value.value
        expect_symbol(stream, Symbol(","))
        y = expect_number(stream, scene).value.value
        expect_symbol(stream, Symbol(","))
        z = expect_number(stream, scene).value.value
        expect_symbol(stream, Symbol("}"))
    else
        throw(WrongTokenType(next_token.loc,"Expected either a 'LiteralType' or a 'LiteralSymbol', got '$(typeof(next_token.value))'",next_token.length))
    end

    Point(x, y, z)
end

"""
    parse_color(stream::InputStream, scene::Scene)

Return a `RGB{Float32}` value from either a named constructor, a symbolic constructor or an appropriate [`Identifier`](@ref).

If the constructor has not exactly three arguments an exception will be thrown.
"""
function parse_color(stream::InputStream, scene::Scene)
    table = scene.variables
    (from_id = parse_by_identifier(ColorType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    next_token = read_token(stream)
    unread_token(stream, next_token)
    if isa(next_token.value, LiteralType)
        expect_type(stream, ColorType)
        kw = (; R = parse_float, G = parse_float, B = parse_float)

        kwargs = generate_kwargs(stream, scene, kw)
        red   = get(kwargs, :R, 0)
        green = get(kwargs, :G, 0)
        blue  = get(kwargs, :B, 0)
    elseif isa(next_token.value, LiteralSymbol)
        expect_symbol(stream, Symbol("<"))
        red = expect_number(stream, scene).value.value
        expect_symbol(stream, Symbol(","))
        green = expect_number(stream, scene).value.value
        expect_symbol(stream, Symbol(","))
        blue = expect_number(stream, scene).value.value
        expect_symbol(stream, Symbol(">"))
    else
        throw(WrongTokenType(next_token.loc,"Expected either a 'LiteralType' or a 'LiteralSymbol', got '$(typeof(next_token.value))'",next_token.length))
    end
    return RGB(red, green, blue)
end

"""
    parse_pigment(stream::InputStream, scene::Scene)

Return a [`Pigment`](@ref) value from either a named constructor or an appropriate [`Identifier`](@ref).

The concrete type is determined by the first keyword after the `PigmentType` token,
which also determines the keyword arguments to be read by [`generate_kwargs`](@ref).
"""
function parse_pigment(stream::InputStream, scene::Scene)
    table = scene.variables
    (from_id = parse_by_identifier(PigmentType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    expect_type(stream, PigmentType)

    type_key = expect_keyword(stream, (
        :Checkered,
        :Image,
        :Uniform
    )).value.value

    kw, res_type = if type_key == :Checkered
        ((; N = parse_int, color_on = parse_color, color_off = parse_color),
         CheckeredPigment
        )
    elseif type_key == :Uniform
        ((; color = parse_color),
         UniformPigment
        )
    elseif type_key == :Image
        ((; image = parse_image),
         ImagePigment
        )
    else
        @assert false "@ $(stream.loc): expect_keyword returned an invalid keyword"
    end

    kwargs = generate_kwargs(stream, scene, kw)

    res_type(; kwargs...)
end

"""
    parse_brdf(stream::InputStream, scene::Scene)

Return a [`BRDF`](@ref) value from either a named constructor or an appropriate [`Identifier`](@ref).

The concrete type is determined by the first keyword after the `BrdfType` token,
which also determines the keyword arguments to be read by [`generate_kwargs`](@ref).
"""
function parse_brdf(stream::InputStream, scene::Scene)
    table = scene.variables
    (from_id = parse_by_identifier(BrdfType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    expect_type(stream, BrdfType)

    type_key = expect_keyword(stream, (
        :Diffuse,
        :Specular
    )).value.value

    kw, res_type = if type_key == :Diffuse
        ((; pigment = parse_pigment),
         DiffuseBRDF
        )
    elseif type_key == :Specular
        ((; pigment = parse_pigment, threshold_angle_rad = parse_float),
         SpecularBRDF
        )
    else
        @assert false "@ $(stream.loc): expect_keyword returned an invalid keyword"
    end

    kwargs = generate_kwargs(stream, scene, kw)

    res_type(; kwargs...)
end

"""
    parse_material(stream::InputStream, scene::Scene)

Return a [`Material`](@ref) value from either a named constructor or an appropriate [`Identifier`](@ref).

The concrete type is determined by the first keyword after the `MaterialType` token,
which also determines the keyword arguments to be read by [`generate_kwargs`](@ref).
"""
function parse_material(stream::InputStream, scene::Scene)
    table = scene.variables
    (from_id = parse_by_identifier(MaterialType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    expect_type(stream, MaterialType)

    kw = (; brdf = parse_brdf, emitted_radiance = parse_pigment)

    kwargs = generate_kwargs(stream, scene, kw)

    Material(; kwargs...)
end

"""
    parse_transformation(stream::InputStream, scene::Scene)

Return a [`Transformation`](@ref) value from either a named constructor,
a construction command, or an appropriate [`Identifier`](@ref).

If the constructor/command/identifier is followed by an `*` operator the transformations will be
concatenated following the usual matrix multiplication rules (i.e. the rightmost transformation will
be applied first).

See also: [`parse_explicit_transformation`](@ref), [`parse_transformation_from_command`](@ref)
"""
function parse_transformation(stream::InputStream, scene::Scene)
    table = scene.variables
    transformation = if (from_id = parse_by_identifier(TransformationType, stream, table)) |> isnothing
        next_token = read_token(stream)
        unread_token(stream, next_token)
        if isa(next_token.value, LiteralType)
            parse_explicit_transformation(stream, scene)
        elseif isa(next_token.value, Command)
            parse_transformation_from_command(stream, scene)
        else
            throw(WrongTokenType(next_token.loc, "Expected either a 'LiteralType' or a 'Command', got '$(typeof(next_token.value))'" , next_token.length))
        end
    else
        read_token(stream)
        from_id
    end

    next_token = read_token(stream)
    next_token.value == LiteralSymbol(Symbol("*")) ?
        transformation * parse_transformation(stream, scene) :
        (unread_token(stream, next_token); transformation)
end

"""
    parse_explicit_transformation(stream::InputStream, scene::Scene)

Return a [`Transformation`](@ref) value from a named constructor taking a 16-long list as the only argument.

There is no way to set the inverse matrix, so it will be calculated by the `inv` algorithm upon construction.

See also: [`parse_transformation`](@ref)
"""
function parse_explicit_transformation(stream::InputStream, scene::Scene)
    table = scene.variables
    expect_type(stream, TransformationType)
    expect_symbol(stream, Symbol("("))
    mat = reshape(parse_list(stream, table, 16), 4, 4)
    expect_symbol(stream, Symbol(")"))
    Transformation(mat)
end

"""
    parse_transformation_from_command(stream::InputStream, scene::Scene)

Return a [`Transformation`](@ref) value from the `ROTATE`, `TRANSLATE`, and `SCALE` [`Command`](@ref)s.

See also: [`parse_transformation`](@ref), [`parse_rotation`](@ref), [`parse_translation`](@ref), [`parse_scaling`](@ref)
"""
function parse_transformation_from_command(stream::InputStream, scene::Scene)
    table = scene.variables
    command_token = expect_command(stream, (ROTATE, TRANSLATE, SCALE))
    unread_token(stream, command_token)
    if command_token.value == ROTATE
        parse_rotation(stream, scene)
    elseif command_token.value == TRANSLATE
        parse_translation(stream, scene)
    elseif command_token.value == SCALE
        parse_scaling(stream, scene)
    else
        @assert false "@ $(command_token.loc): command token has unknown value $(command_token.value)"
    end
end

"""
    parse_rotation(stream::InputStream, scene::Scene)

Return a [`Transformation`](@ref) value from the `ROTATE` [`Command`](@ref).

The argument of this command is a sequence of keyword arguments, with keywords representing the three axes of rotation `.X`, `.Y`, and `.Z`,
followed by a number representing the rotation angle in degrees. Each of these keyword arguments are separated by a `*` operator
which behaves as a concatenation of rotation following the usual rules of matrix multiplication (i.e. the rightmost rotation will be the first to be applied)

See also: [`parse_transformation_from_command`](@ref)
"""
function parse_rotation(stream::InputStream, scene::Scene)
    table = scene.variables
    expect_command(stream, ROTATE)
    expect_symbol(stream, Symbol("("))
    transformation = Transformation()
    while true
        key = expect_keyword(stream, (:X, :Y, :Z)).value.value
        angle_rad = deg2rad(parse_float(stream, scene))
        transformation *= if key == :X
            rotationX(angle_rad)
        elseif key == :Y
            rotationY(angle_rad)
        elseif key == :Z
            rotationZ(angle_rad)
        else
            @assert false "@ $(stream.loc): expect_keyword returned an invalid keyword '$key'"
        end
        expect_symbol(stream, (Symbol("*"), Symbol(")"))).value.value == Symbol(")") && break
    end
    transformation
end

"""
    parse_translation(stream::InputStream, scene::Scene)

Return a [`Transformation`](@ref) value from the `TRANSLATE` [`Command`](@ref).

The arguments of this command are a sequence of keyword arguments, with keywords representing the three axes of translation `.X`, `.Y`, and `.Z`,
followed by a number representing the displacement. Each of these keyword arguments are separated by a `,`.
The order of these arguments is indifferent since, in our euclidean space, translations are commutative transformations.

See also: [`parse_transformation_from_command`](@ref)
"""
function parse_translation(stream::InputStream, scene::Scene)
    expect_command(stream, TRANSLATE)

    kw = (; X = parse_float, Y = parse_float, Z = parse_float)

    kwargs = generate_kwargs(stream, scene, kw)

    translation(get(kwargs, :X, 0f0), get(kwargs, :Y, 0f0), get(kwargs, :Z, 0f0))
end

"""
    parse_scaling(stream::InputStream, scene::Scene)

Return a [`Transformation`](@ref) value from the `SCALE` [`Command`](@ref).

The arguments of this command are a sequence of keyword arguments, with keywords representing the three axes of scaling `.X`, `.Y`, and `.Z`,
followed by a number representing the scaling factor. Each of these keyword arguments are separated by a `,`.
The order of these arguments is indifferent since, in our euclidean space, scalings are commutative transformations.

An alternate form of this command sees only one numeric argument, without parenthesis, and indicates uniform scaling in all directions.

See also: [`parse_transformation_from_command`](@ref)
"""
function parse_scaling(stream::InputStream, scene::Scene)
    table = scene.variables
    expect_command(stream, SCALE)

    next_token = read_token(stream)
    unread_token(stream, next_token)
    (isa(next_token.value, LiteralNumber) || isa(next_token.value, Identifier)) &&
        return scaling(parse_float(stream, scene))

    kw = (; X = parse_float, Y = parse_float, Z = parse_float)

    kwargs = generate_kwargs(stream, scene, kw)

    scaling(get(kwargs, :X, 1f0), get(kwargs, :Y, 1f0), get(kwargs, :Z, 1f0))
end

"""
    parse_camera(stream::InputStream, scene::Scene)

Return a [`Camera`](@ref) value from either a named constructor or an appropriate [`Identifier`](@ref).

The concrete type is determined by the first keyword after the `CameraType` token,
which also determines the keyword arguments to be read by [`generate_kwargs`](@ref).
"""
function parse_camera(stream::InputStream, scene::Scene)
    table = scene.variables
    (from_id = parse_by_identifier(CameraType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    expect_type(stream, CameraType)
    type_key = expect_keyword(stream, (
        :Orthogonal,
        :Perspective
    )).value.value

    kw, res_type = if type_key == :Orthogonal
        ((; aspect_ratio = parse_float, transformation = parse_transformation),
         OrthogonalCamera
        )
    elseif type_key == :Perspective
        ((; aspect_ratio = parse_float, transformation = parse_transformation, screen_distance = parse_float),
         PerspectiveCamera
        )
    else
        @assert false "@ $(stream.loc): expect_keyword returned an invalid keyword"
    end

    kwargs = generate_kwargs(stream, scene, kw)

    res_type(; kwargs...)
end

"""
    parse_pcg(stream::InputStream, scene::Scene)

Return a [`PCG`](@ref) value from either a named constructor or an appropriate [`Identifier`](@ref).
"""
function parse_pcg(stream::InputStream, scene::Scene)
    table = scene.variables
    (from_id = parse_by_identifier(ShapeType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    expect_type(stream, PcgType)

    kw = (; state = parse_int, inc = parse_int)

    kwargs = generate_kwargs(stream, scene, kw)

    PCG(values(kwargs)...)
end

"""
    parse_shape(stream::InputStream, scene::Scene)

Return a [`Shape`](@ref) value from either a named constructor,
a construction command, or an appropriate [`Identifier`](@ref).

See also: [`parse_explicit_shape`](@ref), [`parse_shape_from_command`](@ref)
"""
function parse_shape(stream::InputStream, scene::Scene)
    table = scene.variables
    (from_id = parse_by_identifier(ShapeType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    next_token = read_token(stream)
    unread_token(stream, next_token)
    if isa(next_token.value, LiteralType)
        parse_explicit_shape(stream, scene)
    elseif isa(next_token.value, Command)
        parse_shape_from_command(stream, scene)
    else
        throw(WrongTokenType(next_token.loc, "Expected either a 'LiteralType' or a 'Command', got '$(typeof(next_token.value))'" , next_token.length))
    end
end

"""
    parse_explicit_shape(stream::InputStream, scene::Scene)

Return a [`Shape`](@ref) value from either a named constructor or an appropriate [`Identifier`](@ref).

The concrete type is determined by the first keyword after the `ShapeType` token,
which also determines the keyword arguments to be read by [`generate_kwargs`](@ref).
"""
function parse_explicit_shape(stream::InputStream, scene::Scene)
    expect_type(stream, ShapeType)
    type_key = expect_keyword(stream, (
        :Cube,
        :Cylinder,
        :Plane,
        :Sphere
    )).value.value

    res_type = eval(type_key)
    kw = (; material = parse_material, transformation = parse_transformation)

    kwargs = generate_kwargs(stream, scene, kw)

    res_type(; kwargs...)
end

"""
    parse_shape_from_command(stream::InputStream, scene::Scene)

Return a [`Shape`](@ref) value from the `UNITE`, `INTERSECT`, `DIFF`, and `FUSE` [`Command`](@ref)s.

See also: [`parse_shape`](@ref), [`parse_union`](@ref), [`parse_intersection`](@ref), [`parse_setdiff`](@ref), [`parse_fusion`](@ref)
"""
function parse_shape_from_command(stream::InputStream, scene::Scene)
    table = scene.variables
    command_token = expect_command(stream, (UNITE, INTERSECT, DIFF, FUSE))
    unread_token(stream, command_token)
    if command_token.value == UNITE
        parse_union(stream, scene)
    elseif command_token.value == INTERSECT
        parse_intersection(stream, scene)
    elseif command_token.value == DIFF
        parse_setdiff(stream, scene)
    elseif command_token.value == FUSE
        parse_fusion(stream, scene)
    else
        @assert false "@ $(command_token.loc): command token has unknown value $(command_token.value)"
    end
end

"""
    parse_union(stream::InputStream, scene::Scene)

Return a [`UnionCSG`](@ref) value from the `UNITE` [`Command`](@ref).

See also: [`parse_shape_from_command`](@ref)
"""
function parse_union(stream::InputStream, scene::Scene)
    table = scene.variables
    expect_command(stream, UNITE)
    expect_symbol(stream, Symbol("("))
    shapes = Vector{Shapes}()
    while true
        push!(shapes, parse_shape(stream, scene))
        expect_symbol(stream, (Symbol(","), Symbol(")"))).value.value == Symbol(")") && break
    end
    union(shapes...)
end

"""
    parse_intersection(stream::InputStream, scene::Scene)

Return a [`IntersectionCSG`](@ref) value from the `INTERSECT` [`Command`](@ref).

See also: [`parse_shape_from_command`](@ref)
"""
function parse_intersection(stream::InputStream, scene::Scene)
    table = scene.variables
    expect_command(stream, INTERSECT)
    expect_symbol(stream, Symbol("("))
    shapes = Vector{Shapes}()
    while true
        push!(shapes, parse_shape(stream, scene))
        expect_symbol(stream, (Symbol(","), Symbol(")"))).value.value == Symbol(")") && break
    end
    intersection(shapes...)
end

"""
    parse_setdiff(stream::InputStream, scene::Scene)

Return a [`DiffCSG`](@ref) value from the `DIFF` [`Command`](@ref).

See also: [`parse_shape_from_command`](@ref)
"""
function parse_setdiff(stream::InputStream, scene::Scene)
    table = scene.variables
    expect_command(stream, DIFF)
    expect_symbol(stream, Symbol("("))
    shapes = Vector{Shape}()
    while true
        push!(shapes, parse_shape(stream, scene))
        expect_symbol(stream, (Symbol(","), Symbol(")"))).value.value == Symbol(")") && break
    end
    setdiff(shapes...)
end

"""
    parse_fusion(stream::InputStream, scene::Scene)

Return a [`FusionCSG`](@ref) value from the `FUSE` [`Command`](@ref).

See also: [`parse_shape_from_command`](@ref)
"""
function parse_fusion(stream::InputStream, scene::Scene)
    table = scene.variables
    expect_command(stream, FUSE)
    expect_symbol(stream, Symbol("("))
    shapes = Vector{Shapes}()
    while true
        push!(shapes, parse_shape(stream, scene))
        expect_symbol(stream, (Symbol(","), Symbol(")"))).value.value == Symbol(")") && break
    end
    fusion(shapes...)
end

"""
    parse_renderer_settings(stream::InputStream, scene::Scene)

Return a [`RendererSettings`](@ref) value from either a named constructor or an appropriate [`Identifier`](@ref).

The renderer type is determined by the first keyword after the `RendererType` token,
which also determines the keyword arguments to be read by [`generate_kwargs`](@ref) and stored in the `kwargs` field of the result.
"""
function parse_renderer_settings(stream::InputStream, scene::Scene)
    table = scene.variables
    (from_id = parse_by_identifier(RendererType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    expect_type(stream, RendererType)
    type_key = expect_keyword(stream, (
        :OnOff,
        :Flat,
        :PointLight,
        :PathTracer
    )).value.value

    kw, res_type = if type_key == :OnOff
        ((; on_color = parse_color, off_color = parse_color),
         OnOffRenderer
        )
    elseif type_key == :Flat
        ((; background_color = parse_color),
         FlatRenderer
        )
    elseif type_key == :PointLight
        ((; background_color = parse_color, ambient_color = parse_color),
         PointLightRenderer
        )
    elseif type_key == :PathTracer
        ((; background_color = parse_color,
            rng              = (stream::InputStream, scene::Scene) -> PCG(convert(UInt64, parse_int(stream, scene)), convert(UInt64, parse_int(stream, scene))),
            n                = parse_int,
            max_depth        = parse_int,
            roulette_depth   = parse_int),
         PathTracer
        )
    else
        @assert false "@ $(stream.loc): expect_keyword returned an invalid keyword"
    end

    kwargs = generate_kwargs(stream, scene, kw)

    RendererSettings(res_type, NamedTuple(pairs(kwargs)))
end

"""
    parse_tracer_settings(stream::InputStream, scene::Scene)

Return a [`TracerSettings`](@ref) value from either a named constructor or an appropriate [`Identifier`](@ref).
"""
function parse_tracer_settings(stream::InputStream, scene::Scene)
    table = scene.variables
    (from_id = parse_by_identifier(RendererType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    expect_type(stream, TracerType)

    kw = (; samples_per_side = parse_int, rng = parse_pcg)

    kwargs = generate_kwargs(stream, scene, kw)

    TracerSettings(NamedTuple(pairs(kwargs)))
end

"""
    parse_light(stream::InputStream, scene::Scene)

Return a [`PointLight`](@ref) value from either a named constructor or an appropriate [`Identifier`](@ref).
"""
function parse_light(stream::InputStream, scene::Scene)
    table = scene.variables
    (from_id = parse_by_identifier(RendererType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    expect_type(stream, LightType)

    kw =  (; position = parse_point,
             color = parse_color,
             linear_radius = parse_float)

    kwargs = generate_kwargs(stream, scene, kw)

    PointLight(; kwargs...)
end

"""
    parse_image(stream::InputStream, scene::Scene)

Return an [`HdrImage`](@ref) value from either a named constructor,
a construction command, or an appropriate [`Identifier`](@ref).

See also: [`parse_explicit_image`](@ref), [`parse_image_from_command`](@ref)
"""
function parse_image(stream::InputStream, scene::Scene)
    table = scene.variables
    (from_id = parse_by_identifier(ImageType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    next_token = read_token(stream)
    unread_token(stream, next_token)
    if isa(next_token.value, LiteralType)
        parse_explicit_image(stream, scene)
    elseif isa(next_token.value, Command)
        parse_image_from_command(stream, scene)
    else
        throw(WrongTokenType(next_token.loc, "Expected either a 'LiteralType' or a 'Command', got '$(typeof(next_token.value))'" , next_token.length))
    end
end

"""
    parse_explicit_image(stream::InputStream, scene::Scene)

Return an [`HdrImage`](@ref) value from a named constructor.

There are two versions of the constructor:
- one taking a valid file path [`LiteralString`](@ref) as the only argument and loading the image stored in that file
- the other taking two integer [`LiteralNumber`](@ref)s as width and height and constructing an empty image.

See also: [`parse_image`](@ref)
"""
function parse_explicit_image(stream::InputStream, scene::Scene)
    table = scene.variables
    expect_type(stream, ImageType)
    expect_symbol(stream, Symbol("("))
    next_token = read_token(stream)
    unread_token(stream, next_token)
    type = isa(next_token.value, Identifier) ?
        findfirst(d -> haskey(d, next_token.value.value), table) :
        next_token.value

    image = if isa(type, LiteralString)
        file_path = parse_string(stream, scene)
        isfile(file_path) || throw(InvalidFilePath(next_token.loc,"The file path\n$file_path\ndoes not lead to a file" ,next_token.length))
        try
            load(file_path) |> HdrImage
        catch e
            isa(e, ErrorException) || rethrow(e)
            throw(InvalidFilePath(next_token.loc,"The file path\n$file_path\nleads to a file of invalid format",next_token.length))
        end
    elseif isa(type, LiteralNumber)
        width = parse_int(stream, scene)
        expect_symbol(stream, Symbol(","))
        height = parse_int(stream, scene)
        HdrImage(width, height)
    else
        throw(WrongTokenType(next_token.loc, "Expected a 'LiteralString' file path, a 'LiteralNumber', or an 'Identifier': got a $type", next_token.length))
    end
    expect_symbol(stream, Symbol(")"))
    image
end

"""
    parse_image_from_command(stream::InputStream, scene::Scene)

Return an [`HdrImage`](@ref) value from the `LOAD` [`Command`](@ref).

The `LOAD` [`Command`](@ref) takes only one [`LiteralString`](@ref) representing a valid file path to an image file as an argument.

See also: [`parse_image`](@ref)
"""
function parse_image_from_command(stream::InputStream, scene::Scene)
    table = scene.variables
    expect_command(stream, LOAD)
    next_token = read_token(stream)
    unread_token(stream, next_token)
    file_path = parse_string(stream, scene)
    isfile(file_path) || throw(InvalidFilePath(next_token.loc,"The file path\n$file_path\ndoes not lead to a file" ,next_token.length))
    try
        load(file_path) |> HdrImage
    catch e
        isa(e, ErrorException) || rethrow(e)
        throw(InvalidFilePath(next_token.loc,"The file path\n$file_path\nleads to a file of invalid format",next_token.length))
    end
end

############
## COMMANDS

"""
    parse_set_command(stream::InputStream, scene::Scene)

Push to the 'scene.variables' [`IdTable`](@ref) a constructed value and its identifier variable.
"""
function parse_set_command(stream::InputStream, scene::Scene)
    table = scene.variables
    expect_command(stream, SET)
    while true
        id = read_token(stream)
        isa(id.value, Identifier) || (unread_token(stream, id); break)
        id_name = id.value.value
        if (type = findfirst(d -> haskey(d, id_name), table)) |> !isnothing
            preexisting = table[type][id_name]
            iszero(preexisting.loc.line_num) && return # if identifier was defined at the command line level throw no error and return nothing
            throw(IdentifierRedefinition(id.loc, "Identifier '$(id_name)' has alredy been set at\n$(preexisting.loc)\nIf you want to redefine it first UNSET it.", id.length))
        end
        value, id_type = parse_constructor(stream, scene)
        haskey(table, id_type) ?
            push!(table[id_type], id_name => ValueLoc(value, copy(id.loc))) :
            push!(table, id_type => Dict([id_name => ValueLoc(value, copy(id.loc))]))
    end
end

"""
    parse_unset_command(stream::InputStream, scene::Scene)

Pop identifier variable from the `scene.variables` [`IdTable`](@ref).
"""
function parse_unset_command(stream::InputStream, scene::Scene)
    table = scene.variables
    expect_command(stream, UNSET)
    while true
        id = read_token(stream)
        isa(id.value, Identifier) || (unread_token(stream, id); break)
        id_name = id.value.value
        type = findfirst(d -> haskey(d, id_name), table)
        isnothing(type) && throw(UndefinedIdentifier(id.loc,"Undefined variable '$id_name'" ,id.length))
        pop!(table[type], id_name)
    end
    return
end

"""
    parse_dump_command(stream::InputStream, scene::Scene)

Show the contents of the [`Scene`](@ref). What is shown depends on the [`Keyword`](@ref) following the `DUMP` [`Command`](@ref).

The valid [`Keyword`](@ref)s are `.ALL` for showing the whole [`Scene`](@ref), or the name of one of its fields (in lowercase letters) to show that specific field.
"""
function parse_dump_command(stream::InputStream, scene::Scene)
    table = scene.variables
    expect_command(stream, DUMP)
    valid_keywords = (:ALL, :variables, :world, :lights, :image, :camera, :renderer)
    next_token = read_token(stream)
    if isa(next_token.value, Keyword)
        unread_token(stream, next_token)
        keyword = expect_keyword(stream, valid_keywords).value.value
        keyword == :ALL ?
            display(scene) :
            display(getproperty(scene, keyword))
    elseif isa(next_token.value, Identifier)
        unread_token(stream, next_token)
        id_name = expect_identifier(stream).value.value
        type = findfirst(d -> haskey(d, id_name), table)
        display(table[type][id_name])
    else
        throw(WrongTokenType(next_token.loc, "Expected either a keyword or a valid identifier instead of '$(typeof(next_token.value))'\n"*
                             "Valid keywords: \n\t$(join(valid_keywords, "\n\t"))",next_token.length))
    end
end

"""
    parse_spawn_command(stream::InputStream, scene::Scene)

Push the given `ShapeType` or `LightType` to the `scene.world` [`World`](@ref) or `scene.lights` [`Lights`](@ref) respectively.

See also: [`Scene`](@ref)
"""
function parse_spawn_command(stream::InputStream, scene::Scene)
    table = scene.variables
    expect_command(stream, SPAWN)
    next_token = read_token(stream)
    unread_token(stream, next_token)
    next_val = next_token.value
    (isa(next_val, Identifier) ||
     isa(next_val, LiteralType) ||
     next_val ∈ (UNITE, INTERSECT, DIFF, FUSE)) ||
        throw(WrongTokenType(next_token.loc,"Expected either a constructor or a valid identifier instead of '$(typeof(next_val))'", next_token.length))
    while true
        if isa(next_val, Identifier)
            id_name = expect_identifier(stream).value.value
            type = findfirst(d -> haskey(d, id_name), table)
            if type == ShapeType
                shape = table[type][id_name].value
                push!(scene.world, shape)
            elseif type == LightType
                light = table[type][id_name].value
                push!(scene.lights, light)
            else
                throw(WrongValueType(next_token.loc, "Identifier '$id_name' stores a non-spawnable '$type' object\n" *
                                    "Variable '$id_name' defined at $(table[type][id_name].loc)\n" *
                                     "Spawnable types are:\n\tShapeType\n\tLightType", next_token.length))
            end
        elseif isa(next_val, LiteralType)
            type_token = expect_type(stream, (ShapeType, LightType))
            unread_token(stream, type_token)
            type = type_token.value
            if type == ShapeType
                shape = parse_shape(stream, scene)
                push!(scene.world, shape)
            elseif type == LightType
                light = parse_light(stream, scene)
                push!(scene.lights, light)
            else
                @assert false "@ $(next_token.loc): expect_type returned a non-spawnable type '$type'"
            end
        elseif next_val ∈ (UNITE, INTERSECT, DIFF, FUSE)
            push!(scene.world, parse_shape_from_command(stream, scene))
        else
            break
        end
        next_token = read_token(stream)
        unread_token(stream, next_token)
        next_val = next_token.value
    end
    return
end

"""
    parse_using_command(stream::InputStream, scene::Scene)

Set the given `CameraType`, `ImageType` or `RendererType` to the `scene.camera`, `scene.image`, or `scene.renderer` respectively.

Can only be used once per type in a SceneLang script.

See also: [`Scene`](@ref)
"""
function parse_using_command(stream::InputStream, scene::Scene)
    table = scene.variables
    expect_command(stream, USING)
    next_token = read_token(stream)
    unread_token(stream, next_token)

    (isa(next_token.value, Identifier) ||
     isa(next_token.value, LiteralType) ||
     next_token.value ∈ (LOAD,)) ||
        throw(WrongTokenType(next_token.loc,"Expected either a constructor or a valid identifier instead of '$(typeof(next_token.value))'", next_token.length))


    function already_defined_exception(type::LiteralType)
        @assert type ∈ (CameraType, ImageType, RendererType)
        SettingRedefinition(next_token.loc, "Scene setting of type '$(type)' already in use.", next_token.length)
    end
    while true
        if isa(next_token.value, Identifier)
            id_name = expect_identifier(stream).value.value
            type = findfirst(d -> haskey(d, id_name), table)
            if type == CameraType
                camera = table[type][id_name].value
                isnothing(scene.camera) || throw(already_defined_exception(type))
                scene.camera = camera
            elseif type == ImageType
                image = table[type][id_name].value
                isnothing(scene.image) || throw(already_defined_exception(type))
                scene.image = image
            elseif type == RendererType
                renderer = table[type][id_name].value
                isnothing(scene.renderer) || throw(already_defined_exception(type))
                scene.renderer = renderer
            elseif type == TracerType
                tracer = table[type][id_name].value
                isnothing(scene.tracer) || throw(already_defined_exception(type))
                scene.tracer = tracer
            else
                throw(WrongValueType(next_token.loc, "Variable '$id_name' stores a non-usable '$type' object\n" *
                                        "Variable '$id_name' defined at $(table[type][id_name].loc)\n" *
                                        "Usable types are:\n\tCameraType\n\tImageType\n\tRendererType", next_token.length))
            end
        elseif isa(next_token.value, LiteralType)
            type_token = expect_type(stream, (CameraType, ImageType, RendererType, TracerType))
            unread_token(stream, type_token)
            type =type_token.value
            if type == CameraType
                camera = parse_camera(stream, scene)
                isnothing(scene.camera) || throw(already_defined_exception(type))
                scene.camera = camera
            elseif type == ImageType
                image = parse_explicit_image(stream, scene)
                isnothing(scene.image) || throw(already_defined_exception(type))
                scene.image = image
            elseif type == RendererType
                renderer = parse_renderer_settings(stream, scene)
                isnothing(scene.renderer) || throw(already_defined_exception(type))
                scene.renderer = renderer
            elseif type == TracerType
                tracer = parse_tracer_settings(stream, scene)
                isnothing(scene.tracer) || throw(already_defined_exception(type))
                scene.tracer = tracer
            else
                @assert false "@ $(next_token.loc): expect_type returned a non-spawnable type '$type'"
            end
        elseif isa(next_token.value, Command)
            image = parse_image_from_command(stream, scene)
            isnothing(scene.image) || throw(already_defined_exception(type))
            scene.image = image
        else
            break
        end
        next_token = read_token(stream)
        unread_token(stream, next_token)
    end
    return
end

################
# SCENE PARSING

"""
    parse_scene(stream::InputStream, scene::Scene = Scene())

Return the [`Scene`](@ref) instance resulting parsing the SceneLang script associated with the given [`InputStream`](@ref).
"""
function parse_scene(stream::InputStream, scene::Scene = Scene())
    while !eof(stream)
        command_token = expect_command(stream, (USING, SET, UNSET, SPAWN, DUMP))
        unread_token(stream, command_token)
        command = command_token.value
        if command == USING
            parse_using_command(stream, scene)
        elseif command == SET
            parse_set_command(stream, scene)
        elseif command == UNSET
            parse_unset_command(stream, scene)
        elseif command == SPAWN
            parse_spawn_command(stream, scene)
        elseif command == DUMP
            parse_dump_command(stream, scene)
        else
            @assert false "Got unparsable command '$command' from expect_command."
        end
    end
    scene
end

function print_subsequent_lexer_exceptions(stream::InputStream, except::InterpreterException)
    is_first_exception = true
    while true
        try
            iterate(stream) |> isnothing && break
        catch e
            if is_first_exception
                is_first_exception = false
                printstyled(stderr, "### OTHER LEXER ERRORS ###\n\n", color = :magenta)
            end
            isa(e, InterpreterException) || rethrow(e)
            showerror(stderr, e)
            println(stderr)
        end
    end
    if !is_first_exception
        println(stderr)
        printstyled(stderr, "### MAIN PARSER ERROR ###\n\n", color = :magenta)
    end
    except
end
