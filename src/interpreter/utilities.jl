# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

##########
# Utility

"""
    read_at_line(io, line_num)

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
    read_at_line(file_name, line_num)

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
function isnewline(c::Char)
    c ∈ ('\n', '\r')
end

"""
    issymbol(c::Char)

Check if `c` is in a partucular set of characters used in a SceneLang script.
"""
function issymbol(c::Char)
    c ∈ "()<>[],*"
end