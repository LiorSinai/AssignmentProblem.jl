function get_assignment_cost(cost::AbstractMatrix, assignment::Vector{Int})
    total = 0
    for (i, j) in enumerate(assignment)
        total += cost[i, j]
    end
    total
end