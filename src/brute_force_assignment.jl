"""
    brute_force_assignment(cost)

Solves the assignment problem in `O(n!)≈n/^n` time. 
This is just for test purposes. Rather use `munkres` instead which solves it in `O(n^4)` time.
"""
function brute_force_assignment(cost::AbstractMatrix)
    nrows, ncols = size(cost)
    if (nrows != ncols)
        throw("Not implemeted for non-square matrices")
    end
    chosen = collect(1:nrows)
    min_value = get_assignment_cost(cost, chosen)
    for assignment in Permutation(nrows)
        c = get_assignment_cost(cost, assignment)
        if c < min_value
            min_value = c
            chosen = copy(assignment)
        end
    end
    chosen
end
