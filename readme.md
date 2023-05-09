# Assignment problem algorithms

Solves the [assignment problem](https://en.wikipedia.org/wiki/Hungarian_algorithm) in `O(n^4)` using Munkres' algorithm.

There is also a brute force algorithm which runs in factorial time - approximately `O(n^n)`.
This should be only used for testing.

## Example

```julia
cost = [
    8 4 7;
    5 2 3;
    9 4 8
]
assignment, min_cost = solve_assignment(cost) #([1, 3, 2], 15)
```

## Munkres' algorithm

Step 0: Create an `n`&times;`m` matrix called the cost matrix in which each element represents the cost of assigning one of n workers to one of m jobs. 
Rotate the matrix so that there are at least as many columns as rows and let `k=min(n,m)`. 
    
Step 1: For each row of the matrix, find the smallest element and subtract it from every element in its row. 
Go to Step 2.

Step 2: Find a zero (Z) in the resulting matrix. If there is no starred zero in its row or column, star Z. 
Repeat for each element in the matrix. 
Go to Step 3.

Step 3 (Greedy assignment): Cover each column containing a starred zero. If K columns are covered, the starred zeros describe a complete set of unique assignments. 
In this case, Go to DONE, otherwise, Go to Step 4.

Step 4 (Alternatives): Find a non-covered zero and prime it. If there is no starred zero in the row containing this primed zero, 
Go to Step 5. Otherwise, cover this row and uncover the column containing the starred zero. 
Continue in this manner until there are no uncovered zeros left. Save the smallest uncovered value and Go to Step 6.

Step 5 (Augment path): Construct a series of alternating primed and starred zeros as follows. 
Let Z0 represent the uncovered primed zero found in Step 4. 
Let Z1 denote the starred zero in the column of Z0 (if any). 
Let Z2 denote the primed zero in the row of Z1 (there will always be one). 
Continue until the series terminates at a primed zero that has no starred zero in its column. 
Unstar each starred zero of the series, star each primed zero of the series, erase all primes and uncover every line in the matrix. 
Return to Step 3.

Step 6 (Constraint relaxation): Add the value found in Step 4 to every element of each covered row, and subtract it from every element of each uncovered column. 
Return to Step 4 without altering any stars, primes, or covered lines.

Done: Assignment pairs are indicated by the positions of the starred zeros in the cost matrix. 
If `C[i,j]` is a starred zero, then the element associated with row i is assigned to the element associated with column j.

Sources
- James Munkres, Algorithms for Assignment and Transportation Problems, Journal of the Society for Industrial and Applied Mathematics Volume 5, Number 1, March, 1957
- [Duke University](https://users.cs.duke.edu/~brd/Teaching/Bio/asmb/current/Handouts/munkres.html).

### Time complexity

The worst case is for a matrix `C[i, j] = i * j` where the optimal path lies on the other main diagonal and only one of the row minimums and one of the column minimums is used. This will repeat the step 4-6 loop `n(n+1)` times. The find "save the smallest uncovered value" operation is the slowest step because it requires possibly searching through all `n^2` elements. Hence the algorithm will run in `O(n^4)`.

Apparently there is an improvement to make it `O(n^3)` but I do not know how. Such an improvement would be non-trivial.

## Installation

Download the GitHub repository (it is not registered). Then in the Julia REPL:
```
julia> ] #enter package mode
(@v1.x) pkg> dev path\\to\\AssignmentProblem
julia> using Revise # allows dynamic edits to code
julia> using AssignmentProblem
```

## Testing

Tests can be run with:
```
(@v1.x) pkg> test AssignmentProblem
```

Or in Julia:
```julia
using AssignmentProblem
using Test
include("test/munkres.jl")
```

## Related Packages

[Hungarian.jl](https://github.com/Gnimuc/Hungarian.jl) runs up to 2&times; faster than this version. One reason is it uses more preallocation of arrays.