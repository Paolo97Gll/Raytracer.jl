# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Lexer of SceneLang


"""
    _update_pos!(stream, ch)

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
    unread_char!(stream, ch)

Push a character back to the stream.
"""
function unread_char!(stream::InputStream, ch::Union{Char, Nothing})
    @assert isnothing(stream.saved_char)
    stream.saved_char = ch
    stream.location = stream.saved_location
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
    _parse_string_token(stream, token_location)

Parse the stream into a [`Token`](@ref) with [`LiteralString`](@ref) value.
"""
function _parse_string_token(stream::InputStream, token_location::SourceLocation)
    str = ""
    while true
        ch = read_char!(stream)

        ch == '"' && break

        (isnothing(ch) || isnewline(ch)) && throw(GrammarError(token_location, "Unterminated string", length(str) + 1))

        str *= ch
    end

    return Token(token_location, LiteralString(str))
end

"""
    _parse_float_token(stream, first_char, token_location)

Parse the stream into a [`Token`](@ref) with [`LiteralNumber`](@ref) value.
"""
function _parse_float_token(stream::InputStream, first_char::Char, token_location::SourceLocation)
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
        isa(e, ArgumentError) && rethrow(GrammarError(token_location, "'$str' is an invalid floating-point number", length(str)))
        rethrow(e)
    end

    return Token(token_location, LiteralNumber(value))
end

"""
    _parse_keyword_or_identifier_token(stream, first_char, token_location)

Parse the stream into a [`Token`](@ref) with [`Keyword`](@ref) or [`Identifier`](@ref) value.
"""
function _parse_keyword_or_identifier_token(stream::InputStream, first_char::Char, token_location::SourceLocation)
    str = first_char |> string
    while true
        ch = read_char!(stream)
        # Note that here we do not call "isalpha" but "isalnum": digits are ok after the first character
        !isnothing(ch) && (isdigit(ch) || isletter(ch) || ch == '_') || (unread_char!(stream, ch); break)

        str *= ch
    end

    sym = Symbol(str)
    keywords = instances(Keyword) .|> Symbol
    (index = findfirst(s -> s == sym, keywords)) |> isnothing ?
        Token(token_location, Identifier(sym)) :
        Token(token_location, Keyword(index))
end

"""
    read_token(stream::InputStream)

Read the next token in the stream.
"""
function read_token(stream)
    skip_whitespaces_and_comments(stream)

    # At this point we're sure that ch does *not* contain a whitespace character
    ch = read_char!(stream)
    if isnothing(ch)
        # No more characters in the file, so return a StopToken
        return Token(stream.location, StopToken())
    end

    # At this point we must check what kind of token begins with the "ch" character
    # (which has been put back in the stream with stream.unread_char). First,
    # we save the position in the stream
    token_location = copy(stream.location)

    if issymbol(ch)
        # One-character symbol, like '(' or ','
        return Token(token_location, Symbol(ch))
    elseif ch == '"'
        # A literal string (used for file names)
        return _parse_string_token(stream, token_location)
    elseif isdigit(ch) || ch ∈ ('+', '-', '.')
        # A floating-point number
        return _parse_float_token(stream, ch, token_location)
    elseif isletter(ch) || ch == '_'
        # Since it begins with an alphabetic character, it must either be a keyword
        # or a identifier
        return _parse_keyword_or_identifier_token(stream, ch, token_location)
    else
        # We got some weird character, like '@` or `&`
        throw(GrammarError(stream.location, "Invalid character $ch"))
    end
end
