# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Interpreter for input files

module Interpreter

import Base:
    show, print, eof, copy

export # Interpreter
    SourceLocation, 
    TokenValue,
        Keyword, Identifier, LiteralString, LiteralNumber, StopToken, 
    Token, 
    InputStream,
        open_stream,
        read_char!, unread_char!,
        skip_whitespaces_and_comments,
    #    _update_pos!, _parse_float_token, _parse_keyword_or_identifier_token, _parse_string_token,
        read_token,
    read_at_line, 
    isnewline, issymbol, 
    InterpreterError, 
        GrammarError

const interpreter_dir = "interpreter"
include(joinpath(interpreter_dir, "sourcelocation.jl"))
include(joinpath(interpreter_dir, "token.jl"))
include(joinpath(interpreter_dir, "utilities.jl"))
include(joinpath(interpreter_dir, "exceptions.jl"))
include(joinpath(interpreter_dir, "inputstream.jl"))

for instance ∈ Symbol.(instances(Keyword))
    quote
        export $instance
    end |> eval
end

end # module