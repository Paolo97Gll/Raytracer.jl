# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Parse a scene


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
