using Grumps  # Now you can use the Grumps package
using Test

using LinearAlgebra
using Aqua

# Test.detect_ambiguities( Grumps )

# Aqua.test_all( Grumps; ambiguities=(recursive=false)) 

Grumps.advisory( "number of BLAS threads used = $(BLAS.get_num_threads())" )


cd("test")
@testset "Grumps.jl" begin
    include( "testexample.jl" )
end
