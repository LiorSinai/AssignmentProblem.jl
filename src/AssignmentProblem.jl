module AssignmentProblem

using LinearAlgebra
using SparseArrays

include("common.jl")
include("munkres.jl")
include("permutation.jl")
include("brute_force_assignment.jl")

export get_assignment_cost
export munkres
export brute_force_assignment
export solve_assignment

function solve_assignment(cost::AbstractMatrix; max_iters=default_max_iters(cost))
    nrows, ncols = size(cost)
    transposed = false
    if (nrows > ncols)
        cost = transpose(cost)
        transposed = true
    end
    assignment = munkres(cost; max_iters=max_iters)
    cost_assignment = get_assignment_cost(cost, assignment)
    if transposed
        assignmentT = zeros(Int, nrows)
        for (j, i) in enumerate(assignment)
            assignmentT[i] = j
        end
        assignment = assignmentT
    end
    assignment, cost_assignment
end

end