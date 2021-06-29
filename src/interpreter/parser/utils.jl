# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

########
# UTILS

"""
    evaluate_math_expression(token::Token{MathExpression}, scene::Scene)

Replace all identifiers in the mathematical expression stored in the [`MathExpression`](@ref) token and then evaluate it.
"""
function evaluate_math_expression(token::Token{MathExpression}, scene::Scene)
    vars = scene.variables
    expr = token.value.value
    args = map(expr.args[begin + 1: end]) do arg
        if isa(arg, Symbol)
            arg === :TIME && return scene.time
            if !haskey(vars[LiteralNumber], arg)
                (type = findfirst(d -> haskey(d, arg), vars)) |> isnothing ||
                    throw(WrongTokenType(token.loc, "Variable '$arg' is a '$type' in 'MathExpression': expected 'LiteralNumber'\nVariable '$arg' was declared at $(vars[type][arg].loc)", token.length))
                throw(UndefinedIdentifier(token.loc, "Undefined variable '$arg' in 'MathExpression'", token.length))
            end
            return vars[LiteralNumber][arg].value
        elseif isa(arg, Expr)
            return evaluate_math_expression(Token(token.loc, MathExpression(arg), token.length), vars)
        else
            isfinite(arg) ||
                throw(InvalidExpression(token.loc, "'MathExpression' should not return or contain infinite or NaN values.", token.length))
            return arg
        end
    end
    res = try
        Expr(expr.head, expr.args[begin], args...) |> eval
    catch e
        isa(e, ArgumentError) &&
            throw(InvalidExpression(token.loc, "Julia `eval` has thrown an error:\n`$(e.msg)`\nPlease follow the exception instructions or consult Julia documentation", token.length))
        if isa(e, DomainError)
            msg = "DomainError with " * repr( e.val)
            if isdefined(e, :msg)
                msg *= ":\n" * e.msg
            end
            throw(InvalidExpression(token.loc, "Julia `eval` has thrown an error:\n`$(e.msg)`\nPlease follow the exception instructions or consult Julia documentation", token.length))
        end
        rethrow(e)
    end
    isfinite(res) ||
        throw(InvalidExpression(token.loc, "'MathExpression' should not return or contain infinite or NaN values.", token.length))
    res
end

"""
    function generate_kwargs(stream::InputStream, scene::Scene, kw::NamedTuple)

Return a `Dict{Symbol, Any}` as instructed by the given `kw` `NamedTuple`.

The argument `kw` pairs all the keywords a constructor need with the parsing functions they need.
This function parses keywords and/or values until it reaches the end of the constructor.
The arguments may also be positional, but positional arguments must not follow keyword arguments.
If a keyword is used more than once an exception is thrown.
"""
function generate_kwargs(stream::InputStream, scene::Scene, kw::NamedTuple)
    expect_symbol(stream, Symbol("("))
    kwargs = Dict{Symbol, Any}()
    sizehint!(kwargs, length(kw))
    is_positional_allowed = true
    for i ∈ SOneTo(length(kw))
        token = read_token(stream)
        unread_token(stream, token)
        isa(token.value, LiteralSymbol) && (expect_symbol(stream, Symbol(")")); break)
        key = if isa(token.value, Keyword)
            local key = expect_keyword(stream, keys(kw)).value.value
            haskey(kwargs, key) &&
                throw(InvalidKeyword(token.loc, "Argument `$key` has already been defined", token.length))
            is_positional_allowed = false
            key
        elseif is_positional_allowed
            keys(kw)[i]
        else
            throw(InvalidKeyword(token.loc, "Positional arguments cannot follow keyword arguments", token.length))
        end
        value = kw[key](stream, scene)
        push!(kwargs, key => value)
        expect_symbol(stream, (Symbol(","), Symbol(")"))).value.value == Symbol(")") && break
    end
    kwargs
end

"""
    parse_by_identifier(expected_type::IdTableKey, stream::InputStream, table::IdTable)

If the next token is an [`Identifier`](@ref), check that its type is coherent with `expected_type` and return its value.
"""
function parse_by_identifier(expected_type::IdTableKey, stream::InputStream, table::IdTable)
    next_token = read_token(stream)
    unread_token(stream, next_token)
    if !isa(next_token.value, Identifier)
        return nothing
    end
    id_name = next_token.value.value
    haskey(table[expected_type], id_name) && return table[expected_type][id_name].value
    (type = findfirst(d -> haskey(d, id_name), table)) |> isnothing ||
        throw(WrongTokenType(next_token.loc, "Variable '$id_name' is of type '$type': expected '$expected_type'\nVariable '$id_name' was declared at $(table[type][id_name].loc)", next_token.length))
    throw(UndefinedIdentifier(next_token.loc, "Undefined variable '$id_name'", next_token.length))
end
