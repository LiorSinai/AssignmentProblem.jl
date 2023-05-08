using Test
using AssignmentProblem

@testset "solve" verbose=true begin
    @testset "same" begin 
        cost = ones(5, 5)
        assignment = munkres(cost)
        @test all([x != 0 for x in assignment])
    end 
    
    @testset "simple" begin
        cost = [
            0.1   0.13  0.02 ; 
            0.58  0.61  0.34
        ]
        expected = [1, 3]
        assignment = munkres(cost)
        @test expected == assignment
    end

    @testset "Duke example" begin 
        cost  = [
            1 2 3
            2 4 6 
            3 6 9
        ]
        expected = [3, 2, 1]
        assignment = munkres(cost)

        @test expected == assignment
    end

    @testset "cost(i,j)=i*j" begin 
        n = 10
        cost  = zeros(Int, n, n);
        for i in 1:n
            for j in 1:n
                cost[i, j] = i * j
            end
        end
        expected = collect(n:-1:1)
        assignment = munkres(cost)

        @test assignment == expected
    end

    @testset "simple 1 from Hungarian.jl" begin
        cost = [ 
            0.891171  0.0320582   0.564188  0.8999    0.620615;
            0.166402  0.861136    0.201398  0.911772  0.0796335;
            0.77272   0.782759    0.905982  0.800239  0.297333;
            0.561423  0.170607    0.615941  0.960503  0.981906;
            0.748248  0.00799335  0.554215  0.745299  0.42637
          ]
        expected = [2, 3, 5, 1, 4]
        assignment = munkres(cost)
        @test expected == assignment
    end

    @testset "simple 2 from Hungarian.jl" begin
        cost = [
            24   5   6  12  18 ;
            1   7  13  19  25 ;
            8  14  20  21   2 ;
          ]
        expected = [2, 1, 5]
        assignment = munkres(cost)
        @test expected == assignment
    end

    @testset "UInt16 from Hungarian.jl" begin
        cost = UInt16[ 
            28092 44837 19882 39481 59139;
            26039 46258 38932 51057 9;
            11527 59487 61993 29072 8734;
            10691 16977 12796 16370 14266;
            5199  42319 34194 41332 16472
          ]
        expected = [3, 5, 4, 2, 1]
        assignment = munkres(cost)
        @test expected == assignment
    end

    @testset "random" begin 
        cost = [ 
            0.696805  0.946949  0.724759  0.820038   0.862807 ;
            0.75627   0.772123  0.914251  0.207518   0.220206 ;
            0.115525  0.790986  0.685634  0.249029   0.357599 ;
            0.842297  0.734221  0.168913  0.457646   0.25052 ;
            0.588022  0.464698  0.647981  0.0297565  0.14824 ;
        ]
        expected = [2, 5, 1, 3, 4] # verified with brute force
        assignment = munkres(cost)
        @test assignment == expected
    end 

    @testset "distances betweem random points" begin 
        cost = [
            2.24958  27.9875   8.67857  21.6568  13.1429;
            5.12785  41.9321   8.10041  32.6583   4.50145;
            6.17217  39.2846  15.0946   31.982   17.9779;
        ]
        expected = [3, 5, 1]
        assignment = munkres(cost)
        @test assignment == expected
    end
 
end