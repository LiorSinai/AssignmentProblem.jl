using Test
using AssignmentProblem: Permutation

@testset "Permutation" begin
    @testset "n=1" begin
        perms = collect(Permutation(1))
        expected = [[1]]
        @test issetequal(perms, expected)
    end

    @testset "n=2" begin
        perms = collect(Permutation(2))
        expected = [
            [1, 2],
            [2, 1]
        ]
        @test issetequal(perms, expected)
    end

    @testset "n=3" begin
        perms = collect(Permutation(3))
        expected = [
            [1, 3, 2],
            [2, 3, 1],
            [3, 2, 1],
            [1, 2, 3],
            [2, 1, 3],
            [3, 1, 2],
        ]
        @test issetequal(perms, expected)
    end

    @testset "n=3" begin
        perms = collect(Permutation(3))
        expected = [
            [1, 3, 2],
            [2, 3, 1],
            [3, 2, 1],
            [1, 2, 3],
            [2, 1, 3],
            [3, 1, 2],
        ]
        @test issetequal(perms, expected)
    end

    @testset "n=5" begin
        perms = collect(Permutation(5))
        uniques = unique(perms)
        @test length(uniques) == 120
    end
end