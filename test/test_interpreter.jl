# Raytracer.jl
# Raytracing for the generation of photorealistic images in Julia
# Copyright (c) 2021 Samuele Colombo, Paolo Galli

# Unit test file for interpreter.jl (SceneLang interpreter)
# TODO revise tests!


@testset "TestLexer" begin
    expected = [Token(SourceLocation("test_interpreter_script.sl", 2, 2), SPAWN, ),
    Token(SourceLocation("test_interpreter_script.sl", 2, 8), Identifier(:number), ),
    Token(SourceLocation("test_interpreter_script.sl", 2, 15), LiteralNumber(-9.0f0), ),
    Token(SourceLocation("test_interpreter_script.sl", 6, 2), DESPAWN, ),
    Token(SourceLocation("test_interpreter_script.sl", 6, 10), Identifier(:number), ),
    Token(SourceLocation("test_interpreter_script.sl", 7, 2), SPAWN, ),
    Token(SourceLocation("test_interpreter_script.sl", 7, 8), Identifier(:another_number), ),
    Token(SourceLocation("test_interpreter_script.sl", 7, 23), LiteralNumber(0.009f0), ),
    Token(SourceLocation("test_interpreter_script.sl", 8, 2), SPAWN, ),
    Token(SourceLocation("test_interpreter_script.sl", 8, 8), Identifier(:string), ),
    Token(SourceLocation("test_interpreter_script.sl", 8, 15), LiteralString("string"), ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 2), SPAWN, ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 8), Identifier(:color_list), ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 19), Symbol("["), ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 20), :<, ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 21), LiteralNumber(1.0f0), ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 24), Symbol(","), ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 26), LiteralNumber(3.0f0), ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 27), Symbol(","), ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 29), LiteralNumber(4.0f0), ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 30), :>, ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 31), Symbol(","), ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 33), :<, ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 34), LiteralNumber(7.0f0), ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 35), Symbol(","), ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 37), LiteralNumber(9.0f0), ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 38), Symbol(","), ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 40), Symbol("("), ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 41), LiteralNumber(10.0f0), ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 43), :*, ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 44), LiteralNumber(2.0f0), ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 45), Symbol(")"), ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 46), :>, ),
    Token(SourceLocation("test_interpreter_script.sl", 9, 47), Symbol("]"), )]

    i = 1

    open_stream("test_interpreter_script.sl") do stream
        while true
            try
                it = iterate(stream)
                isnothing(it) && break
                token, _ = it
                @test isa(token.value, typeof(expected[i].value))
            catch e
                @test isa(e, GrammarException)
            end
            i += 1
        end
    end
end
