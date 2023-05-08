using Test
using AssignmentProblem

@testset verbose = true "AssignmentProblem" begin
    include("unit_tests.jl")
    include("munkres.jl")
    include("permutation.jl")
end