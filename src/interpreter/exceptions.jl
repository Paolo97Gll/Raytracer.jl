using Base: String
# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Interpreter exceptions


"""
    InterpreterException <: Exception

Abstract type for all SceneLang interpreter errors.

See also: [`GrammarException`](@ref)
"""
abstract type InterpreterException <: Exception end

macro make_exception(name::Symbol, descriptive_str::AbstractString)
    struct_doc = 
        """
            $name <: InterpreterException
        
        $descriptive_str
        
        See also: [`InterpreterException`](@ref)
        
        # Fields
        
        - `location::SourceLocation`: location of the error
        - `msg::AbstractString`: descriptive error message
        - `len::Int`: how many characters are involved in the error
        """
    constructor_doc = 
        """
            $name(location::SourceLocation, msg::AbstractString)
        
        Construct an instance of [`$name`](@ref) with `len = 1`.
        """

    quote
        @doc $struct_doc $name

        struct $(esc(name)) <: InterpreterException
            location::SourceLocation
            msg::AbstractString
            len::Int
        end
        
        @doc $constructor_doc $name(::SourceLocation, ::AbstractString)

        function $(esc(name))(location::SourceLocation, msg::AbstractString)
            $(esc(name))(location, msg, 1)
        end
    end
end

function Base.showerror(io::IO, e::InterpreterException)
    print(io, typeof(e))
    printstyled(io, " @ ", e.location, color=:light_black)
    println(io)
    printstyled(io, e.msg, color=:red)
    println(io)
    printstyled(io, "source: ", color=:light_black)
    println(io, read_at_line(e.location.file_name, e.location.line_num))
    printstyled(io, " " ^ (e.location.col_num + 7), color=:light_black)
    printstyled(io, "^" ^ e.len, color=:red)
end

function Base.showerror(io::IO, e::InterpreterException, bt; backtrace = false)
    try
        showerror(io, e)
    finally
        nothing
    end
end
 
@make_exception BadCharacter           "There is an invalid character in the SceneLang script."
@make_exception UnfinishedExpression   "A special environment (e.g. a string, mathematical expression, list...) has been opened and not closed."
@make_exception UndefinedIdentifier    "The given identifier has not been defined in the script."
@make_exception WrongTokenType         "The given value is of a different type than expected by the syntax."
@make_exception WrongValueType         "The given value has a different type than expected by the syntax."
@make_exception InvalidKeyword         "The given keyword is not valid in the given context."
@make_exception InvalidType            "The given type does not exist."
@make_exception InvalidCommand         "The given command does not exist."
@make_exception InvalidExpression      "The given expression contains invalid elements. Capabilities are restrained to contain malicious code injection."
@make_exception InvalidSymbol          "The given symbol is not valid in the given context."
@make_exception InvalidNumber          "The token has an invalid numerical format."
@make_exception InvalidSize            "The given collection has an invalid size in the given context."
@make_exception InvalidFilePath        "The given file path is invalid."
@make_exception IdentifierRedefinition "An identifier is being redefined without being unset first."
@make_exception SettingRedefinition    "A rendering setting is being defined multiple times."