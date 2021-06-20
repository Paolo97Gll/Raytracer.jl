# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Parser of SceneLang
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

const IdTableKey = Union{Type{<:TokenValue}, LiteralType}

"""
    IdTable

Alias to `Dict{Type{<:TokenValue}, Dict{Symbol, Token{V} where {V}}}`.

Dictionary with all the variables read from a SceneLang script.
"""
const IdTable = Dict{IdTableKey, Dict{Symbol, ValueLoc}}

function Base.show(io::IO, ::MIME"text/plain", table::IdTable)
    for (key, subdict) ∈ pairs(table)
        printstyled(io, "#### ", key, " ####", color = :blue)
        println()
        for (id, value) ∈ pairs(subdict)
            printstyled(io, id, color = :green)
            println(io, " = ", value)
        end
        println(io)
    end
end

const RendererSettings = NamedTuple{(:type, :kwargs), Tuple{Type{<:Renderer}, NamedTuple}}

const CameraOrNot = Union{Camera, Nothing}
const RendererOrNot = Union{RendererSettings, Nothing}
const ImageOrNot = Union{HdrImage, Nothing}

mutable struct Scene
    variables::IdTable
    world::World
    lights::Lights
    image::ImageOrNot
	camera::CameraOrNot
	renderer::RendererOrNot
end

function Scene(; variables::IdTable = IdTable(), 
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
                (type = findfirst(d -> haskey(d, arg), vars)) |> isnothing || 
                    throw(WrongTokenType(token.loc, "Variable '$arg' is a '$type' in 'MathExpression': expected 'LiteralNumber'\nVariable '$arg' was declared at $(vars[type][arg].loc)", token.length))
                throw(UndefinedIdentifier(token.loc, "Undefined variable '$arg' in 'MathExpression'", token.length))
            end
            return vars[arg].value
        elseif isa(arg, Expr)
            return evaluate_math_expression(arg, vars)
        else
            return arg
        end
    end
    Expr(expr.head, expr.args[begin], args...) |> eval
end

function generate_kwargs(stream::InputStream, table::IdTable, kw::NamedTuple)
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
        value = kw[key](stream, table) 
        push!(kwargs, key => value)
        expect_symbol(stream, (Symbol(","), Symbol(")"))).value.value == Symbol(")") && break
    end
    kwargs
end

function parse_by_identifier(expected_type::IdTableKey, stream::InputStream, table::IdTable)
    next_token = read_token(stream)
    unread_token(stream, next_token)
    if !isa(next_token.value, Identifier)
        return nothing
    end
    id_name = next_token.value.value
    haskey(table[expected_type], id_name) && return table[expected_type][id_name].value
    (type = findfirst(d -> haskey(d, arg), vars)) |> isnothing || 
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
                                                      "Expected a keyword instead of '$(typeof(token.value))'\nValid keywords: $(join(keywords_list, ", "))",
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
    token.value == command || throw(InvalidSymbol(token.loc,
                                                  "Invalid command '$(token.value)'\nValid commands: $command",
                                                  token.length))
    token
end

"""
    expect_command(stream::InputStream, commands::Union{NTuple{N, Command} where {N}, AbstractVector{Command}})

Read a token from an [`InputStream`](@ref) and check that it is a [`Command`](@ref) in the given `commands`.
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
        (type = findfirst(d -> haskey(d, var_name), vars)) |> isnothing || 
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

function parse_int(stream::InputStream, table::IdTable)
    n_token = if parse_by_identifier(LiteralNumber, stream, table) |> isnothing 
        expect_number(stream, table)
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

function parse_float(stream::InputStream, table::IdTable)
    (from_id = parse_by_identifier(LiteralNumber, stream, table)) |> isnothing || (read_token(stream); return from_id)
    expect_number(stream, table).value.value
end

# parse_vector(s: InputStream, scene: Scene) -> Vec
function parse_list(stream::InputStream, table::IdTable)
    (from_id = parse_by_identifier(ListType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    vec = Vector{Float32}()
    sizehint!(vec, 16) # I do not expect the users to define any list longer than 16, even if they have the ability to
    expect_symbol(stream, Symbol("["))
    push!(vec, expect_number(stream, table))
    while expect_symbol(stream, (Symbol(","), Symbol("]"))).value.value == Symbol(",")
        push!(vec, expect_number(stream, table))
    end
    vec
end

function parse_list(stream::InputStream, table::IdTable, list_length::Int)
    @assert list_length >= 1 "list must have size of at least 1"
    if (from_id = parse_by_identifier(ListType, stream, table)) |> !isnothing 
        token = read_token(stream)
        if length(from_id) != list_length 
            id_name = token.value.value
            throw(InvalidSize(token.loc, "Variable '$(id_name)' stores a list of length $(length(from_id)): expected length $list_length.\nVariable '$id_name' was declared at $(table[ListType][id_name].loc)", token.length))
        end
        return from_id
    end
    expect_symbol(stream, Symbol("["))
    vec = SVector{list_length, Float32}([expect_number(stream, table).value.value, 
                                         ((expect_symbol(stream, Symbol(",")); expect_number(stream, table).value.value) for _ ∈ SOneTo(list_length - 1))...
                                        ])

    expect_symbol(stream, Symbol("]"))

    vec
end

function parse_point(stream::InputStream, table::IdTable)
    (from_id = parse_by_identifier(PointType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    expect_symbol(stream, Symbol("{"))
    x = expect_number(stream, table).value.value 
    expect_symbol(stream, Symbol(","))
    y = expect_number(stream, table).value.value 
    expect_symbol(stream, Symbol(","))
    z = expect_number(stream, table).value.value 
    expect_symbol(stream, Symbol("}"))

    Point(x, y, z)
end

# parse_color(s: InputStream, scene: Scene) -> Color
function parse_color(stream::InputStream, table::IdTable)
    (from_id = parse_by_identifier(ColorType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    expect_symbol(stream, Symbol("<"))
    red = expect_number(stream, table).value.value
    expect_symbol(stream, Symbol(","))
    green = expect_number(stream, table).value.value
    expect_symbol(stream, Symbol(","))
    blue = expect_number(stream, table).value.value
    expect_symbol(stream, Symbol(">"))
    return RGB(red, green, blue)
end

# parse_pigment(s: InputStream, scene: Scene) -> Pigment
function parse_pigment(stream::InputStream, table::IdTable)
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
        @assert false "expect_keyword returned an invalid keyword"
    end

    kwargs = generate_kwargs(stream, table, kw)

    res_type(; kwargs...)
end

# parse_brdf(s: InputStream, scene: Scene) -> BRDF
function parse_brdf(stream::InputStream, table::IdTable)
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
        @assert false "expect_keyword returned an invalid keyword"
    end

    kwargs = generate_kwargs(stream, table, kw)

    res_type(; kwargs...)
end

# parse_material(s: InputStream, scene: Scene) -> Tuple[str, Material]
function parse_material(stream::InputStream, table::IdTable)
    (from_id = parse_by_identifier(MaterialType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    expect_type(stream, MaterialType)

    kw = (; brdf = parse_brdf, emitted_radiance = parse_pigment) 

    kwargs = generate_kwargs(stream, table, kw)

    Material(; kwargs...)
end

# parse_transformation(input_file, scene: Scene)
function parse_transformation(stream::InputStream, table::IdTable)
    (from_id = parse_by_identifier(TransformationType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    next_token = read_token(stream)
    unread_token(stream, next_token)
    transformation = if isa(next_token.value, LiteralType)
        parse_explicit_transformation(stream, table)
    elseif isa(next_token.value, Command)
        parse_transformation_from_command(stream, table)
    else
        throw(WrongTokenType(next_token.loc, "Expected either a 'LiteralType' or a 'Command', got '$(eltype(next_token.value))'" , next_token.length))
    end

    next_token = read_token(stream)
    next_token.value == LiteralSymbol(Symbol("*")) ? 
        transformation * parse_transformation(stream, table) : 
        (unread_token(stream, next_token); transformation)
end

function parse_explicit_transformation(stream::InputStream, table::IdTable)
    expect_type(stream, TransformationType)
    mat = reshape(parse_list(stream, table, 16), 4, 4)
    Transformation(mat)
end

function parse_transformation_from_command(stream::InputStream, table::IdTable)
    command_token = expect_command(stream, (ROTATE, TRANSLATE, SCALE))
    unread_token(stream, command_token)
    if command_token.value == ROTATE
        parse_rotation(stream, table)
    elseif command_token.value == TRANSLATE
        parse_translation(stream, table)
    elseif command_token.value == SCALE
        parse_scaling(stream, table)
    else
        @assert false "command token has unknown value $(command_token.value)"
    end
end

function parse_rotation(stream::InputStream, table::IdTable)
    expect_command(stream, ROTATE)
    expect_symbol(stream, Symbol("("))
    transformation = Transformation()
    while true
        key = expect_keyword(stream, (:X, :Y, :Z)).value.value
        angle_rad = deg2rad(parse_float(stream, table))
        transformation *= if key == :X
            rotationX(angle_rad)
        elseif key == :Y
            rotationY(angle_rad)
        elseif key == :Z
            rotationZ(angle_rad)
        else
            @assert false "expect_keyword returned an invalid keyword '$key'"
        end
        expect_symbol(stream, (Symbol("*"), Symbol(")"))).value.value == Symbol(")") && break
    end
    transformation
end

function parse_translation(stream::InputStream, table::IdTable)
    expect_command(stream, TRANSLATE)

    kw = (; X = parse_float, Y = parse_float, Z = parse_float) 

    kwargs = generate_kwargs(stream, table, kw)

    translation(get(kwargs, :X, 0f0), get(kwargs, :Y, 0f0), get(kwargs, :Z, 0f0)) 
end

function parse_scaling(stream::InputStream, table::IdTable)
    expect_command(stream, SCALE)

    next_token = read_token(stream)
    unread_token(stream, next_token)
    (isa(next_token.value, LiteralNumber) || isa(next_token.value, Identifier)) &&
        return scaling(parse_float(stream, table))

    kw = (; X = parse_float, Y = parse_float, Z = parse_float) 

    kwargs = generate_kwargs(stream, table, kw)

    scaling(get(kwargs, :X, 1f0), get(kwargs, :Y, 1f0), get(kwargs, :Z, 1f0)) 
end

# parse_camera(s: InputStream, scene) -> Camera
function parse_camera(stream::InputStream, table::IdTable)
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
        @assert false "expect_keyword returned an invalid keyword"
    end

    kwargs = generate_kwargs(stream, table, kw)

    res_type(; kwargs...)
end

####################
function parse_shape(stream::InputStream, table::IdTable)
    (from_id = parse_by_identifier(ShapeType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    expect_type(stream, ShapeType)
    type_key = expect_keyword(stream, (
        :Cube, 
        :Cylinder, 
        :Plane, 
        :Sphere
    )).value.value

    res_type = eval(type_key)
    kw = (; material = parse_material, transformation = parse_transformation)

    kwargs = generate_kwargs(stream, table, kw)

    res_type(; kwargs...)
end

function parse_shape(res_type::Type{<:Shape}, stream::InputStream, table::IdTable)
    (from_id = parse_by_identifier(ShapeType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    expect_type(stream, ShapeType)
    expect_keyword(stream, (Symbol(res_type),)).value.value

    kw = (; material = parse_material, transformation = parse_transformation)

    kwargs = generate_kwargs(stream, table, kw)

    res_type(; kwargs...)
end

# parse_sphere(s: InputStream, scene: Scene) -> Sphere
# parse_plane(s: InputStream, scene: Scene) -> Plane