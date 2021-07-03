# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Parsers for CLI


"""
    parse_variables_from_string(str::AbstractString; table::IdTable = IdTable()) -> IdTable

Parse a string containing comma separated identifier-constructor pairs and return the resulting [`IdTable`](@ref).
"""
function parse_variables_from_string(str::AbstractString; table::IdTable = IdTable()) :: IdTable
    scene = Scene(variables = table)
    str = replace(str, r"\s+" => " ")
    buff = IOBuffer(str)
    stream = InputStream(buff, "/COMMANDLINE"; line_num = 0)
    while !eof(stream)
        id = expect_identifier(stream)
        id_name = id.value.value
        findfirst(d -> haskey(d, id_name), table) |> isnothing ||
            throw(IdentifierRedefinition(id.loc, "Identifier '$(id_name)' has alredy been set.", id.length))
        value, id_type = parse_constructor(stream, scene)
        haskey(table, id_type) ?
            push!(table[id_type], id_name => ValueLoc(value, copy(id.loc))) :
            push!(table, id_type => Dict([id_name => ValueLoc(value, copy(id.loc))]))
        next_token = read_token(stream)
        isa(next_token.value, StopToken) && break
        unread_token(stream, next_token)
        expect_symbol(stream, Symbol(","))
    end
    table
end
