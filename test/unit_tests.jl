using Test
using SparseArrays
using AssignmentProblem: row_minimums!
using AssignmentProblem: greedy_assignment!
using AssignmentProblem: find_alternatives!, make_path, augment_path!
using AssignmentProblem:  find_smallest_uncovered, constraint_relaxation!
using AssignmentProblem: DONE, FIND_ALTERNATIVES, AUGMENT_PATH, CONSTRAINT_RELAXATION

@testset "row minimums" verbose=true begin
    @testset "square" begin
        cost = [1 2; 7 9]
        Δrows = zeros(2);

        row_minimums!(cost, Δrows)
        expected = [-1, -7]
        @test Δrows == expected
    end

    @testset "rectangle" begin
        cost = [1 2 3; 10 9 7]
        Δrows = zeros(2);

        row_minimums!(cost, Δrows)
        expected = [-1, -7]
        @test Δrows == expected
    end
end

@testset "step 3: greedy assignment" verbose=true begin
    @testset "2-star" begin
        cost = [1 2 3; 9 10 7]
        Δrow = [-1, -7];
        mask = spzeros(Int8, 2, 3);

        rowSTAR, colSTAR, row2colSTAR = greedy_assignment!(cost, Δrow, mask)

        expected_rowSTAR = BitVector((1, 1))
        expected_colSTAR = BitVector((1, 0, 1))
        expected_row2colSTAR = Dict(1 => 1, 2 => 3)
        expected_mask = sparse([1, 2],[1, 3], Int8.([2, 2]), 2, 3)
        
        @test rowSTAR == expected_rowSTAR
        @test colSTAR == expected_colSTAR
        @test row2colSTAR == expected_row2colSTAR
        @test mask == expected_mask
    end

    @testset "1-star 1-zero" begin
        cost = [1 2 3; 7 9 10]
        Δrow = [-1, -7];
        mask = spzeros(Int8, 2, 3);

        rowSTAR, colSTAR, row2colSTAR = greedy_assignment!(cost, Δrow, mask)

        expected_rowSTAR = Bool[1, 0]
        expected_colSTAR = Bool[1, 0, 0]
        expected_row2colSTAR = Dict(1 => 1)
        expected_mask = sparse([1, 2],[1, 1], Int8.([2, 1]), 2, 3)
        expected_col_covered = colSTAR

        @test rowSTAR == expected_rowSTAR
        @test colSTAR == expected_colSTAR
        @test row2colSTAR == expected_row2colSTAR
        @test mask == expected_mask
    end
end

@testset "step 4: alternatives" verbose=true begin
    @testset "1-star 1-zero 0-prime" begin
        cost = [1 2 3; 7 9 10];
        Δrow = [-1, -7];
        mask = sparse([1, 2],[1, 1], Int8.([2, 1]), 2, 3)
        col_covered = BitVector((1, 0, 0));
        row_covered = falses(2);
        rowSTAR = BitVector((1, 0));
        row2colSTAR = Dict(1 => 1)

        step_num = find_alternatives!(mask, row_covered, col_covered, rowSTAR, row2colSTAR)

        expected_mask = sparse([1, 2],[1, 1], Int8.([2, 1]), 2, 3)
        expected_col_covered = BitVector((1, 0, 0))
        expected_row_covered = BitVector((0, 0))

        @test step_num == CONSTRAINT_RELAXATION
        @test mask == expected_mask
        @test col_covered == expected_col_covered
        @test row_covered == expected_row_covered
    end

    @testset "1-star 1-zero 1-prime" begin
        cost = [1 1 3; 7 9 10];
        Δrow = [-1, -7];
        mask = sparse([1, 1, 2],[1, 2, 1], Int8.([2, 1, 1]), 2, 3)
        col_covered = BitVector((1, 0, 0));
        row_covered = falses(2);
        rowSTAR = BitVector((1, 0));
        row2colSTAR = Dict(1 => 1)

        step_num = find_alternatives!(mask, row_covered, col_covered, rowSTAR, row2colSTAR)

        expected_mask = sparse([1, 1, 2],[1, 2, 1], Int8.([2, 3, 3]), 2, 3)
        expected_col_covered = BitVector((0, 0, 0))
        expected_row_covered = BitVector((1, 0))
        @test step_num == AUGMENT_PATH
        @test mask == expected_mask
        @test col_covered == expected_col_covered
        @test row_covered == expected_row_covered
    end
end

@testset "step 5: augment path" verbose=true begin
    @testset "1-star 1-zero 1-prime" begin
        cost = [1 1 3; 7 9 10];
        Δrow = [-1, -7];
        mask = sparse([1, 1, 2],[1, 2, 1], Int8.([2, 3, 3]), 2, 3)
        rowSTAR = BitVector((1, 0))
        row2colSTAR = Dict(1=>1)
        col_covered = BitVector((0, 0, 0))
        row_covered = BitVector((1, 0))

        path = make_path(mask, row_covered, col_covered)
        expected_path = [(2, 1), (1, 1), (1, 2)]
        @test path == expected_path

        step_num = augment_path!(mask, row_covered, col_covered, rowSTAR, row2colSTAR)

        expected_mask = sparse([1, 1, 2],[1, 2, 1], Int8.([1, 2, 2]), 2, 3)
        expected_rowSTAR = trues(2)
        expected_row_covered = falses(2)
        expected_col_covered = BitVector((1, 1, 0))
        expected_row2colSTAR = Dict(1=>2, 2=>1)

        @test step_num == DONE
        @test mask == expected_mask
        @test rowSTAR == expected_rowSTAR
        @test row_covered == expected_row_covered
        @test expected_col_covered == col_covered
        @test row2colSTAR == expected_row2colSTAR
    end
end

@testset "step 6: constraint relaxation" verbose=true begin
    @testset "1-star 1-zero" begin 
        cost = [1 2 3; 7 9 10];
        Δrow = [-1, -7];
        Δcol = [0, 0, 0];
        mask = sparse([1, 2],[1, 1], Int8.([2, 1]), 2, 3)
        row_covered = falses(2)
        col_covered = BitVector((1, 0, 0))
        rowSTAR = BitVector((1, 0))
        row2colSTAR = Dict(1 => 1)

        step_num = constraint_relaxation!(cost, mask, row_covered, col_covered, Δrow, Δcol, rowSTAR, row2colSTAR)
        
        expected_mask = sparse([1, 2, 1],[1, 1, 2], Int8.([2, 1, 1]), 2, 3)
        expected_rowSTAR = BitVector((1, 0))
        expected_row2colSTAR = Dict(1 => 1)
        expected_Δrow = [-1, -7];
        expected_Δcol = [0, -1, -1];
        
        @test step_num == FIND_ALTERNATIVES
        @test rowSTAR == expected_rowSTAR
        @test row2colSTAR == expected_row2colSTAR
        @test Δrow == expected_Δrow
        @test Δcol == expected_Δcol
        @test mask == expected_mask
    end

    @testset "Undo zero" begin
        cost  = [
            1 2 3
            2 4 6 
            3 6 9
        ]
        Δrow = [-1, -2, -3];
        Δcol = [0, -1, -2]
        mask = sparse([1, 1, 1, 2, 3],[1, 2, 3, 1, 1], Int8.([1, 2, 3, 2, 1]), 3, 3)
        rowSTAR = BitVector((1, 1, 0))
        row2colSTAR = Dict(2 => 1, 1=>2)

        col_covered = BitVector((1, 0, 0))
        row_covered = BitVector((1, 0, 0))
        step_num = constraint_relaxation!(cost, mask, row_covered, col_covered, Δrow, Δcol, rowSTAR, row2colSTAR)
        
        expected_Δrow = [0, -2, -3]
        expected_Δcol = [0, -2, -3]
        expected_mask = sparse([1, 1, 2, 3, 2],[2, 3, 1, 1, 2], Int8.([2, 3, 2, 1, 1]), 3, 3)
        expected_rowSTAR = BitVector((1, 1, 0))
        expected_row2colSTAR = Dict(2 => 1, 1=>2)

        @test step_num == FIND_ALTERNATIVES
        @test rowSTAR == expected_rowSTAR
        @test row2colSTAR == expected_row2colSTAR
        @test Δrow == expected_Δrow
        @test Δcol == expected_Δcol
        @test mask == expected_mask
    end
end
