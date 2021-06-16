# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Interpreter utility functions


"""
    read_at_line(io::IO, line_num::Int)

Read the `line_num`-th line of `io`.
"""
function read_at_line(io::IO, line_num::Int)
    seekstart(io)
    for _ ∈ 1:line_num - 1
        readline(io)
    end
    readline(io)
end

"""
    read_at_line(file_name::String, line_num::Int)

Read the `line_num`-th line of a file named `file_name`.
"""
function read_at_line(file_name::String, line_num::Int)
    open(file_name, "r") do io
        read_at_line(io, line_num)
    end
end

"""
    isnewline(c::Char)

Check if `c` is a newline character.
"""
isnewline(c::Char) = c ∈ ('\n', '\r')

"""
    issymbol(c::Char)

Check if `c` is in a partucular set of characters used in a SceneLang script.
"""
issymbol(c::Char) = c ∈ "()<>[],*"

const valid_operations = (:+, :-, :*, :/, :%, :div, :^)

"""
    isvalid(expr::Expr, str_len::Int)

Return `true` if the given expression is valid in a SceneLang script, else throw an appropriate exception.
"""
function isvalid(expr::Expr, str_len::Int)
    expr.head == :call || 
        throw(GrammarException(token_location, "Invalid mathematical expression: expression head is not a call", str_len + 1))
    expr.args[begin] ∈ valid_operations || 
        throw(GrammarException(token_location, "Invalid mathematical expression: contains invalid operation $(expr.args[begin])\nValid operations are: " * join(valid_operations, ", "), str_len + 1))
    (invalid = findfirst(arg -> !isa(arg, Union{Integer, AbstractFloat, Expr, Symbol}), expr.args[begin + 1:end])) |> isnothing || 
        throw(GrammarException(token_location, "Invalid mathematical expression: contains invalid operand $(expr.args[invalid + 1])\nValid operands are instances of `Integer`, `AbstractFloat`, `Symbol` or `Expr`", str_len + 1))
    
    return all(arg -> (isa(arg, Expr) ? isvalid(arg, str_len) : true), expr.args[begin + 1:end])
end

"""
    evaluate_math_expression(token::Token{MathExpression}, vars::IdTable)

Replace all identifiers in the mathematical expression stored in the [`MathExpression`](@ref) token and then evaluate it.
"""
function evaluate_math_expression(token::Token{MathExpression}, vars::IdTable)
    expr = token.value.value
    args = map(expr.args[begin + 1: end]) do arg
        if isa(arg, Symbol)
            if !haskey(vars[LiteralNumber], arg) 
                (type = findfirst(type -> haskey(vars[type], arg), keys(vars))) |> isnothing || 
                    throw(GrammarException(stream.location, "Variable '$arg' is a '$type' in 'MathExpression': expected 'LiteralNumber'"))
                throw(GrammarException(stream.location, "Undefined variable '$arg' in 'MathExpression'", token.length))
            end
            return vars[arg]
        elseif isa(arg, Expr)
            return evaluate_math_expression(arg, vars)
        else
            return arg
        end
    end
    Expr(expr.head, expr.args[begin], args...) |> eval
end