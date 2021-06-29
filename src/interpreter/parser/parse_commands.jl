# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

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