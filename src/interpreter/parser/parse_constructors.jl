# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

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
            return (parse_transformation(stream, scene), TransformationType)
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

Return a `Int` value from either a [`LiteralNumber`](@ref) constructor, the `TIME` command, an appropriate [`MathExpression`](@ref), or an appropriate [`Identifier`](@ref).

If the `Float32` number is not exactly representing an integer number an exception is thrown.
"""
function parse_int(stream::InputStream, scene::Scene)
    next_token = read_token(stream)
    unread_token(stream, next_token)
    n = parse_float(stream, scene)

    try
        convert(Int, n)
    catch e
        isa(e, InexactError) || rethrow(e)
        throw(WrongValueType(next_token.loc,"The given number is not convertible to an integer since it is not round",next_token.length))
    end
end

"""
    parse_float(stream::InputStream, scene::Scene)

Return a `Float32` value from either a [`LiteralNumber`](@ref) constructor, the `TIME` command, an appropriate [`MathExpression`](@ref), or an appropriate [`Identifier`](@ref).
"""
function parse_float(stream::InputStream, scene::Scene)
    table = scene.variables
    (from_id = parse_by_identifier(LiteralNumber, stream, table)) |> isnothing || (read_token(stream); return from_id)
    token = read_token(stream)
    if isa(token.value, MathExpression) 
        res = evaluate_math_expression(token, scene)
        isa(res, Number) ||
        throw(InvalidExpression(token.loc, "`MathExpression` should return a `Number`: got a `$(typeof(res))`" , token.length))
        return res
    end
    token.value == TIME && return scene.time
    unread_token(stream, token)
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

Return a [`Point`](@ref) value from either a named constructor, a symbolic constructor, an appropriate [`MathExpression`](@ref), or an appropriate [`Identifier`](@ref).

If the constructor has not exactly three arguments an exception will be thrown.
"""
function parse_point(stream::InputStream, scene::Scene)
    table = scene.variables
    (from_id = parse_by_identifier(PointType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    next_token = read_token(stream)
    if isa(next_token.value, MathExpression) 
        res = evaluate_math_expression(next_token, scene)
        isa(res, Point) ||
        throw(InvalidExpression(next_token.loc, "`MathExpression` should return a `Point`: got a `$(typeof(res))`" , next_token.length))
        return res
    end
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
        x = parse_float(stream, scene)
        expect_symbol(stream, Symbol(","))
        y = parse_float(stream, scene)
        expect_symbol(stream, Symbol(","))
        z = parse_float(stream, scene)
        expect_symbol(stream, Symbol("}"))
    else
        throw(WrongTokenType(next_token.loc,"Expected either a 'LiteralType' or a 'LiteralSymbol', got '$(typeof(next_token.value))'",next_token.length))
    end

    Point(x, y, z)
end

"""
    parse_color(stream::InputStream, scene::Scene)

Return a `RGB{Float32}` value from either a named constructor, a symbolic constructor, an appropriate [`MathExpression`](@ref), or an appropriate [`Identifier`](@ref).

If the constructor has not exactly three arguments an exception will be thrown.
"""
function parse_color(stream::InputStream, scene::Scene)
    table = scene.variables
    (from_id = parse_by_identifier(ColorType, stream, table)) |> isnothing || (read_token(stream); return from_id)
    next_token = read_token(stream)
    if isa(next_token.value, MathExpression) 
        res = evaluate_math_expression(next_token, scene)
        isa(res, RGB) ||
        throw(InvalidExpression(next_token.loc, "`MathExpression` should return a `RGB`: got a `$(typeof(res))`" , next_token.length))
        return res
    end
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
        red = parse_float(stream, scene)
        expect_symbol(stream, Symbol(","))
        green = parse_float(stream, scene)
        expect_symbol(stream, Symbol(","))
        blue = parse_float(stream, scene)
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
    expect_command(stream, UNITE)
    expect_symbol(stream, Symbol("("))
    shapes = Vector{Shape}()
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
    expect_command(stream, INTERSECT)
    expect_symbol(stream, Symbol("("))
    shapes = Vector{Shape}()
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
    expect_command(stream, FUSE)
    expect_symbol(stream, Symbol("("))
    shapes = Vector{Shape}()
    while true
        push!(shapes, parse_shape(stream, scene))
        expect_symbol(stream, (Symbol(","), Symbol(")"))).value.value == Symbol(")") && break
    end
    fuse(shapes...)
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
