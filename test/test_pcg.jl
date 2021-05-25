pcg = PCG()
@test pcg.state == UInt64(1753877967969059832) repr(pcg.state |> Int)
@test pcg.inc == UInt64(109) repr(pcg.inc |> Int)

for expected in [2707161783, 2068313097,
                    3122475824, 2211639955,
                    3215226955, 3421331566]
    @test expected == (found = rand(pcg, UInt32)) "Exp: $expected, Found: $(repr(found |> Int))"
end