# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Lexer of SceneLang


"""
    _update_pos!(stream::InputStream, ch::Union{Char, Nothing})

Update `stream.location` after having read `ch` from the stream.
"""
function _update_pos!(stream::InputStream, ch::Union{Char, Nothing})
    if isnothing(ch)
        return
    elseif ch == '\n'
        stream.location.line_num += 1
        stream.location.col_num = 1
    elseif ch == '\t'
        stream.location.col_num += stream.tabulations
    else
        stream.location.col_num += 1
    end
end

"""
    read_char!(stream::InputStream)

Read a new character from the stream.
"""
function read_char!(stream::InputStream)
    if !isnothing(stream.saved_char)
        # Recover the "unread" character and return it
        ch = stream.saved_char
        stream.saved_char = nothing
    else
        # Read a new character from the stream
        ch = eof(stream) ? nothing : read(stream.stream, Char)
    end

    stream.saved_location = copy(stream.location)
    _update_pos!(stream, ch)

    return ch
end

"""
    unread_char!(stream::InputStream, ch::Union{Char, Nothing})

Push a character back to the stream. Accepts a `nothing` value to deal with eof.
"""
function unread_char!(stream::InputStream, ch::Union{Char, Nothing})
    @assert isnothing(stream.saved_char)
    stream.saved_char = ch
    stream.location = copy(stream.saved_location)
end

"""
    skip_whitespaces_and_comments(stream::InputStream)

Keep reading characters until a non-whitespace character is found out of a commented line.
"""
function skip_whitespaces_and_comments(stream::InputStream)
    ch = read_char!(stream)
    isnothing(ch) && return
    while isspace(ch) || ch == '#'
        ch == '#' && while (dump = read_char!(stream); !isnothing(dump) && !isnewline(dump)) end
        ch = read_char!(stream)
        isnothing(ch) && return
    end

    # Put the non-whitespace character back
    unread_char!(stream, ch)
end

"""
    _parse_string_token(stream::InputStream, token_location::SourceLocation)

Parse the stream into a [`Token`](@ref) with [`LiteralString`](@ref) value.
"""
function _parse_string_token(stream::InputStream, token_location::SourceLocation)
    str = ""
    while true
        ch = read_char!(stream)

        ch == '"' && break

        (isnothing(ch) || isnewline(ch)) && throw(UnfinishedExpression(token_location, "Unterminated string", length(str) + 1))

        str *= ch
    end

    return Token(token_location, LiteralString(str), length(str))
end

"""
    _parse_number_token(stream::InputStream, first_char::Char, token_location::SourceLocation)

Parse the stream into a [`Token`](@ref) with [`LiteralNumber`](@ref) value.
"""
function _parse_number_token(stream::InputStream, first_char::Char, token_location::SourceLocation)
    str = first_char |> string
    while true
        ch = read_char!(stream)

        if isnothing(ch) || isspace(ch) || issymbol(ch)
            unread_char!(stream, ch)
            break
        end

        str *= ch
    end

    value = try
        parse(Float32, str)
    catch e
        isa(e, ArgumentError) && 
            rethrow(InvalidNumber(token_location, "'$str' is an invalid number format\n"*
                    "Valid formats only include digits, '+' or '-', dots, and letters 'e' or 'E'\n"*
                    "Examples: +9e3, -300.5, 5e-7", length(str)))
        rethrow(e)
    end

    return Token(token_location, LiteralNumber(value), length(str))
end

"""
    _parse_keyword_token(stream::InputStream, first_char::Char, token_location::SourceLocation)

Parse the stream into a [`Token`](@ref) with [`Keyword`](@ref) value.
"""
function _parse_keyword_token(stream::InputStream, token_location::SourceLocation)
    str = ""
    while true
        ch = read_char!(stream)
        # Note that here we do not call "isalpha" but "isalnum": digits are ok after the first character
        !isnothing(ch) && (isdigit(ch) || isletter(ch) || ch == '_') || (unread_char!(stream, ch); break)

        str *= ch
    end

    sym = Symbol(str)
    Token(token_location, Keyword(sym), length(str) + 1)
end

"""
    _parse_command_or_type_token(stream::InputStream, first_char::Char, token_location::SourceLocation)

Parse the stream into a [`Token`](@ref) with [`Command`](@ref) or [`Type`](@ref) value.
"""
function _parse_command_or_type_token(stream::InputStream, first_char::Char, token_location::SourceLocation)
    start_loc = copy(stream.saved_location)
    str = first_char |> string
    while true
        ch = read_char!(stream)
        # Note that here digits are ok after the first character
        !isnothing(ch) && (isdigit(ch) || isletter(ch) || ch == '_') || (unread_char!(stream, ch); break)

        str *= ch
    end

    class, sym = all(ch -> isuppercase(ch) || ch == '_', str) ? 
        (Command,     Symbol(str)) : 
        (LiteralType, Symbol(str * "Type"))

    keywords = instances(class) .|> Symbol
    if (index = findfirst(s -> s == sym, keywords)) |> isnothing 
        valid_instances = replace.(
            last.(
                split.(
                    repr.(
                        instances(class)
                    ), 
                ".")
            ),
            Ref(r"Type$" => "")
        )
        throw((class <: Command ? InvalidCommand : InvalidType)(start_loc, 
            "'$str' is not a valid '$class'.\nValid $(class)s are:\n\t" * join(valid_instances, "\n\t"), length(str))) 
    end
    Token(token_location, class(index - 1), length(str))
end

"""
    _parse_identifier_token(stream::InputStream, first_char::Char, token_location::SourceLocation)

Parse the stream into a [`Token`](@ref) with [`Identifier`](@ref) value.
"""
function _parse_identifier_token(stream::InputStream, first_char::Char, token_location::SourceLocation)
    str = first_char |> string
    while true
        ch = read_char!(stream)
        # Note that here we do not call "isalpha" but "isalnum": digits are ok after the first character
        !isnothing(ch) && (isdigit(ch) || isletter(ch) || ch == '_') || (unread_char!(stream, ch); break)

        str *= ch
    end

    sym = Symbol(str)
    Token(token_location, Identifier(sym), length(str))
end

"""
    _parse_math_expression_token(stream::InputStream, token_location::SourceLocation)

Parse the stream into a [`Token`](@ref) with [`MathExpression`](@ref) value.
"""
function _parse_math_expression_token(stream::InputStream, token_location::SourceLocation)
    str = ""
    while true
        ch = read_char!(stream)

        ch == '$' && break

        (isnothing(ch) || isnewline(ch)) && throw(UnfinishedExpression(token_location, "Unterminated mathematical expression", length(str) + 1))

        str *= ch
    end

    expr = Meta.parse(str)
    Raytracer.isvalid(expr, length(str), token_location)
    return Token(token_location, MathExpression(expr), length(str) + 2)
end

"""
    read_token(stream::InputStream)

Read the next token in the stream.
"""
function read_token(stream::InputStream)
    if !isnothing(stream.saved_token)
        result = stream.saved_token
        stream.saved_token = nothing
        return result
    end

    skip_whitespaces_and_comments(stream)

    # At this point we're sure that ch does *not* contain a whitespace character
    ch = read_char!(stream)
    if isnothing(ch)
        # No more characters in the file, so return a StopToken
        return Token(stream.location, StopToken(), 1)
    end

    # Check if we got some non ASCII character
    isascii(ch) || throw(BadCharacter(stream.location, "Invalid character $ch: only ASCII charachters are supported"))
    
    # At this point we must check what kind of token begins with the "ch" character
    # (which has been put back in the stream with stream.unread_char). First,
    # we save the position in the stream
    token_location = copy(stream.saved_location)

    if issymbol(ch)
        # One-character symbol, like '(' or ','
        return Token(token_location, LiteralSymbol(Symbol(ch)), 1)
    elseif ch == '"'
        # A literal string (used for file names)
        return _parse_string_token(stream, token_location)
    elseif ch == '$'
        # A math expression
        return _parse_math_expression_token(stream, token_location)
    elseif ch == '.'
        return _parse_keyword_token(stream, token_location)
    elseif isdigit(ch) || ch ∈ ('+', '-')
        # A floating-point number
        return _parse_number_token(stream, ch, token_location)
    elseif isuppercase(ch)
        # Since it begins with an uppercase letter, it must be either a command or a type
        return _parse_command_or_type_token(stream, ch, token_location)
    elseif islowercase(ch) || ch == '_'
        # Since it begins with a lowercase letter, it must be an identifier
        return _parse_identifier_token(stream, ch, token_location)
    else
        # We got some weird ASCII character, like '@` or `&`
        throw(BadCharacter(stream.location, "Invalid character $ch"))
    end
end

"""
    unread_token(stream::InputStream, ch::Token)

Push a token back to the stream.
"""
function unread_token(stream::InputStream, token::Token)
    @assert isnothing(stream.saved_token)
    stream.saved_token = token
end