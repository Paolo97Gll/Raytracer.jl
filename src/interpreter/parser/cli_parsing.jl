# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

function parse_variables_from_string(str::AbstractString) :: IdTable
    table = IdTable()
    str = replace(str, r"\s+" => " ")
    buff = IOBuffer(str)
    stream = InputStream(buff, "COMMANDLINE"; line_num = 0)
    while !eof(stream)
        id = read_token(stream)
        id_name = expect_identifier.value.value
        findfirst(d -> haskey(d, id_name), table) |> isnothing ||
            error("Identifier '$(id_name)' has alredy been set.")
        value, id_type = parse_constructor(stream, scene)
        haskey(table, id_type) ?
            push!(table[id_type], id_name => ValueLoc(value, copy(id.loc))) :
            push!(table, id_type => Dict([id_name => ValueLoc(value, copy(id.loc))]))
        next_token = read_token(stream)
        isa(next_token, StopToken) && break
        unread_token(stream, next_token)
        expect_symbol(stream, Symbol(";"))
    end
    table
end