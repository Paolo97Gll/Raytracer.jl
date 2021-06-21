# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Interpreter for input files

module Interpreter

using Base:
    SizeUnknown

using StaticArrays:
    SVector, @SVector, SOneTo

using Raytracer
using FileIO

import Base:
    show, showerror, print, eof, copy, IteratorSize

export # Interpreter
    SourceLocation,
    TokenValue,
        Keyword, Identifier, LiteralString, LiteralNumber, LiteralSymbol, MathExpression, StopToken,
    Token,
    InputStream,
        open_stream,
    Scene,
    InterpreterException

const interpreter_dir = "interpreter"
include(joinpath(interpreter_dir, "sourcelocation.jl"))
include(joinpath(interpreter_dir, "token.jl"))
include(joinpath(interpreter_dir, "exceptions.jl"))
include(joinpath(interpreter_dir, "utilities.jl"))
include(joinpath(interpreter_dir, "inputstream.jl"))
include(joinpath(interpreter_dir, "lexer.jl"))
include(joinpath(interpreter_dir, "parser.jl"))


end # module
