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
issymbol(c::Char) = c ∈ "{}()<>[],*"

"""
    valid_operations

A dictionary storing the operation `Symbol` and a function `::Int -> ::Bool` that return true when the number of arguments is under a threshold.

For example the pair `:+ => ( ::Int) -> true` indicates that the operation `+` is valid with any number of arguments,
while the pair `:floor => (n::Int) -> n == 1` indicates that the operation `floor` is valid only if it has one argument.

See also: [`Raytracer.isvalid`](@ref)
"""
const valid_operations = Dict(:+     => (; f = ( ::Int) -> true,        signature = "+(x...)"),
                              :-     => (; f = (n::Int) -> n == 2,      signature = "-(x, y)"),
                              :*     => (; f = ( ::Int) -> true,        signature = "*(x...)"),
                              :/     => (; f = (n::Int) -> n == 2,      signature = "/(x, y)"),
                              :%     => (; f = (n::Int) -> n == 2,      signature = "%(x, y)"),
                              :^     => (; f = (n::Int) -> n == 2,      signature = "^(x, y)"),
                              :div   => (; f = (n::Int) -> n == 2,      signature = "div(x, y)"),
                              :floor => (; f = (n::Int) -> n == 1,      signature = "floor(x)"),
                              :ceil  => (; f = (n::Int) -> n == 1,      signature = "ceil(x)"),
                              :round => (; f = (n::Int) -> n == 1,      signature = "round(x)"),
                              :exp   => (; f = (n::Int) -> n == 1,      signature = "exp(x)"),
                              :exp2  => (; f = (n::Int) -> n == 1,      signature = "exp2(x)"),
                              :exp10 => (; f = (n::Int) -> n == 1,      signature = "exp10(x)"),
                              :log   => (; f = (n::Int) -> n == 1,      signature = "log(x)"),
                              :log2  => (; f = (n::Int) -> n == 1,      signature = "log2(x)"),
                              :log10 => (; f = (n::Int) -> n == 1,      signature = "log10(x)"),
                              :log1p => (; f = (n::Int) -> n == 1,      signature = "log1p(x)"),
                              :sin   => (; f = (n::Int) -> n == 1,      signature = "sin(x)"),
                              :cos   => (; f = (n::Int) -> n == 1,      signature = "cos(x)"),
                              :tan   => (; f = (n::Int) -> n == 1,      signature = "tan(x)"),
                              :asin  => (; f = (n::Int) -> n == 1,      signature = "asin(x)"),
                              :acos  => (; f = (n::Int) -> n == 1,      signature = "acos(x)"),
                              :atan  => (; f = (n::Int) -> 1 <= n <= 2, signature = "atan(x, [y])"),
                              :Point => (; f = (n::Int) -> n == 3,      signature = "Point(x, y, z)"),
                              :RGB   => (; f = (n::Int) -> n == 3,      signature = "RGB(r, g, b)"),
                             )

"""
    Raytracer.isvalid(expr::Expr, str_len::Int, token_location::SourceLocation)

Return `true` if the given expression is valid in a SceneLang script, else throw an appropriate exception using `str_len` and `token_location`.

See also: [`valid_operations`](@ref)
"""
function Raytracer.isvalid(expr::Expr, str_len::Int, token_location::SourceLocation)
    expr.head == :call ||
        throw(InvalidExpression(token_location, "Invalid mathematical expression: expression head is not a call", str_len + 1))
    op_name = expr.args[begin]
    isa(op_name, Symbol) ||
        throw(InvalidExpression(token_location, "Invalid mathematical expression: operation name '$op_name' is not a symbol" , str_len + 1))
    op_name ∈ keys(valid_operations) ||
        throw(InvalidExpression(token_location, "Invalid mathematical expression: contains invalid operation $(expr.args[begin])\nValid operations are: " * join(valid_operations, ", "), str_len + 1))
    (invalid = findfirst(arg -> !isa(arg, Union{Integer, AbstractFloat, Expr, Symbol}), expr.args[begin + 1:end])) |> isnothing ||
        throw(InvalidExpression(token_location, "Invalid mathematical expression: contains invalid operand $(expr.args[invalid + 1])\nValid operands are instances of `Integer`, `AbstractFloat`, `Symbol` or `Expr`", str_len + 1))
    valid_operations[op_name].f(length(expr.args) - 1) ||
        throw(InvalidExpression(token_location, "Invalid mathematical expression: operation signature is '$(valid_operations[op_name].signature)', got '$(op_name)' with $(length(expr.args[begin+1:end])) arguments", str_len + 1))

    return all(arg -> (isa(arg, Expr) ? Raytracer.isvalid(arg, str_len, token_location) : true), expr.args[begin + 1:end])
end