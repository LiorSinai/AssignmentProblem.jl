# Zero markers used in Munkres algorithm
const NONZERO = Int8(0)
const ZERO = Int8(1)   # Ordinary zero
const STAR = Int8(2)   # Optimal zero
const PRIME = Int8(3)  # Alternative optimal zero

# Step numbers
const DONE = Int8(0)
const FIND_ALTERNATIVES = Int8(1)
const AUGMENT_PATH = Int8(2)
const CONSTRAINT_RELAXATION = Int8(3)

"""
    munkres(cost; debug=false; max_iters=default_max_iters(cost))

This solves the assignment problem using the algorithm developed by J. Munkres.
It runs in `O(n^4)` time.

Source: James Munkres, Algorithms for Assignment and Transportation Problems, Journal of the Society for Industrial and Applied Mathematics Volume 5, Number 1, March, 1957
"""
function munkres(cost::AbstractMatrix{T}; debug=false, max_iters=default_max_iters(cost)) where {T<:Real}
    #setup
    nrows, ncols = size(cost);
    if (nrows > ncols)
        throw("Non-square matrix should have more columns than rows: $nrows > $ncols")
    end
    # for tracking results
    Δrow = zeros(T, nrows);
    Δcol = zeros(T, ncols);
    mask = spzeros(Int8, nrows, ncols);
    # for covering lines
    row_covered = falses(nrows);

    #step 1
    debug && println("step 1")
    row_minimums!(cost, Δrow)

    #step 2
    debug && println("step 2")
    rowSTAR, col_covered, row2colSTAR = greedy_assignment!(cost, Δrow, mask)
    # rowSTAR and row2colSTAR are used in find_alternatives! but need to be kept up to date in other steps 

    #step 3
    debug && println("step 3")
    step_num = have_assigned_all(nrows, col_covered)
    
    iters = 0
    while step_num != DONE
        iters += 1
        if (iters > max_iters)
            throw("Error: max iterations=$(max_iters) exceeded")
        end
        #debug && println("step $(step_num + 3)")
        if step_num == FIND_ALTERNATIVES
            step_num = find_alternatives!(mask, row_covered, col_covered, rowSTAR, row2colSTAR)
        elseif step_num == AUGMENT_PATH
            step_num = augment_path!(mask, row_covered, col_covered, rowSTAR, row2colSTAR)
        elseif step_num == CONSTRAINT_RELAXATION
            step_num = constraint_relaxation!(cost, mask, row_covered, col_covered, Δrow, Δcol, rowSTAR, row2colSTAR)
        else 
            step_num = DONE
        end
    end
    debug && println("Steps taken: $(iters + 3)")
    assignment = get_current_assignment(mask)
    assignment
end

function default_max_iters(cost::AbstractMatrix) 
    # C[i, j] = i*j is worst case
    n = size(cost, 1)
    n * (n + 2)
end

function row_minimums!(cost::AbstractMatrix, Δrow::AbstractVector)
    nrows, ncols = size(cost)
    for i in 1:nrows
        m = cost[i, 1]
        for j in 2:ncols
            m = min(m, cost[i, j])
        end
        Δrow[i] = -m
    end
    Δrow
end

function have_assigned_all(nrows::Int, col_covered::BitVector)
    count(col_covered) == nrows ? DONE : FIND_ALTERNATIVES
end

function get_current_cost(cost::AbstractMatrix, Δrow::AbstractVector, Δcol::AbstractVector)
    current = copy(cost)
    for (i, val) in enumerate(Δrow)
        current[i, :] .+= val
    end
    for (j, val) in enumerate(Δcol)
        current[:, j] .+= val
    end
    current
end

function get_current_assignment(mask::SparseMatrixCSC)
    nrows, ncols = size(mask)
    assignment = zeros(Int, nrows)
    rows = rowvals(mask)
    for j in axes(mask, 2)
        for r in nzrange(mask, j)
            i = rows[r]
            if mask[i, j] == STAR
                assignment[i] = j
            end
        end
    end
    assignment
end

"""
    greedy_assignment!(cost, Δrow, mask)
 Step 2: Find a zero (Z) in the resulting matrix. If there is no starred zero in its row or column, star Z. 
 Repeat for each element in the matrix. 
 Go to Step 3.
"""
function greedy_assignment!(cost::AbstractMatrix, Δrow::AbstractVector, mask::SparseMatrixCSC)
    nrows, ncols = size(cost)

    rowSTAR = falses(nrows)
    colSTAR = falses(ncols)
    row2colSTAR = Dict{Int,Int}()

    for i in 1:nrows
        for j in 1:ncols
            c = cost[i, j] + Δrow[i]
            if c == 0.0
                mask[i, j] = ZERO
                if !colSTAR[j] && !rowSTAR[i]
                    mask[i, j] = STAR
                    rowSTAR[i] = true
                    colSTAR[j] = true
                    row2colSTAR[i] = j
                end
            end
        end
    end
    rowSTAR, colSTAR, row2colSTAR
end

"""
    find_alternatives!(mask, row_covered, col_covered, rowSTAR, row2colSTAR)

Step 4: Find a noncovered zero and prime it. If there is no starred zero in the row containing this primed zero, 
Go to Step 5. Otherwise, cover this row and uncover the column containing the starred zero. 
Continue in this manner until there are no uncovered zeros left. Save the smallest uncovered value and Go to Step 6.
"""
function find_alternatives!(
    mask::SparseMatrixCSC, row_covered::BitVector, col_covered::BitVector, rowSTAR::BitVector, row2colSTAR::Dict
    )
    covered = 0
    num_zeros = nnz(mask)
    rows = rowvals(mask)

    iters = 0
    while covered < num_zeros
        iters += 1
        covered = 0
        for j in axes(mask, 2)
            for r in nzrange(mask, j)
                i = rows[r]
                if !col_covered[j] && !row_covered[i]
                    mask[i, j] = PRIME
                    if !(rowSTAR[i])
                        return AUGMENT_PATH
                    else
                        row_covered[i] = true
                        col_covered[row2colSTAR[i]] = false
                    end
                else 
                    covered += 1
                end
            end
        end
    end
    CONSTRAINT_RELAXATION
end

function star_short_cuts(mask::SparseMatrixCSC)
    nrows, ncols = size(mask)
    rowSTAR = falses(nrows)
    row2colSTAR = Dict{Int,Int}()
    
    (Is, Js, Vs) = findnz(mask)
    for (i, j, val) in zip(Is, Js, Vs)
        if val == STAR
            rowSTAR[i] = true
            row2colSTAR[i] = j
        end
    end
    rowSTAR, row2colSTAR
end

"""
    path_augmentation!(mask, row_covered, col_covered, rowSTAR, row2colSTAR)

Step 5: Construct a series of alternating primed and starred zeros as follows. 
Let Z0 represent the uncovered primed zero found in Step 4. 
Let Z1 denote the starred zero in the column of Z0 (if any). 
Let Z2 denote the primed zero in the row of Z1 (there will always be one). 
Continue until the series terminates at a primed zero that has no starred zero in its column. 
Unstar each starred zero of the series, star each primed zero of the series, erase all primes and uncover every line in the matrix. 
Return to Step 3.
"""
function augment_path!(
    mask::SparseMatrixCSC, row_covered::BitVector, col_covered::BitVector, rowSTAR::BitVector, row2colSTAR::Dict
    )
    nrows, ncols = size(mask)
    path = make_path(mask, row_covered, col_covered)
    convert_path!(mask, path)
    cleanup!(rowSTAR, row_covered, row2colSTAR)
    erase_primes_and_cover_stars!(mask, rowSTAR, col_covered, row2colSTAR)
    step_num = have_assigned_all(nrows, col_covered)
    step_num
end

function make_path(mask::SparseMatrixCSC, row_covered::BitVector, col_covered::BitVector)
    Z0 = find_first_prime(mask, row_covered, col_covered)
    if isnothing(Z0)
        throw("No uncovered prime found")
    end
    path = [Z0]
    # It is inefficient to search through rows of sparse matrices because they are stored in columns
    # As a workaround, transpose the matrix
    Is, Js, Vs = findnz(mask)
    maskT = sparse(Js, Is, Vs, size(mask, 2), size(mask, 1)) 
    iters = 0
    while true
        iters += 1
        i = find_star_in_col(mask, Z0[2])
        if (i == -1)
            break
        end
        Z1 = (i, Z0[2])
        push!(path, Z1)
        j = find_prime_in_row(maskT, i)
        if (j == -1)
            throw("No prime in row with starred zero")
        end
        Z2 = (i, j)
        push!(path, Z2)
        Z0 = Z2
    end
    path
end

function find_first_prime(mask::SparseMatrixCSC, row_covered::BitVector, col_covered::BitVector)
    rows = rowvals(mask)
    for j in axes(mask, 2)
        for r in nzrange(mask, j)
            i = rows[r]
            if mask[i, j]==PRIME && !col_covered[j] && !row_covered[i]
                return (i, j)
            end
        end
    end
    return nothing
end

function find_star_in_col(mask::SparseMatrixCSC, j::Int)
    rows = rowvals(mask)
    for r in nzrange(mask, j)
        i = rows[r]
        if mask[i, j] == STAR
            return i
        end
    end
    -1 
end

function find_prime_in_row(maskT::SparseMatrixCSC, i::Int)
    cols = rowvals(maskT)
    for r in nzrange(maskT, i)
        j = cols[r]
        if maskT[j, i] == PRIME
            return j
        end
    end
    -1
end

function convert_path!(mask::SparseMatrixCSC, path::Vector{Tuple{Int, Int}})
    for loc in path
        old_val = mask[loc[1], loc[2]]
        newval = old_val == PRIME ? STAR : ZERO
        mask[loc[1], loc[2]] = newval
    end
end

function cleanup!(rowSTAR::BitVector, row_covered::BitVector, row2colSTAR::Dict)
    fill!(rowSTAR, false)
    empty!(row2colSTAR)
    fill!(row_covered, false)
end

function erase_primes_and_cover_stars!(
    mask::SparseMatrixCSC, rowSTAR::BitVector, colSTAR::BitVector, row2colSTAR::Dict
    )
    rows = rowvals(mask)
    for j in axes(mask, 2)
        for r in nzrange(mask, j)
            i = rows[r]
            if mask[i, j] == PRIME
                mask[i, j] = ZERO
            elseif mask[i, j] == STAR
                rowSTAR[i] = true
                colSTAR[j] = true
                row2colSTAR[i] = j
            end
        end
    end
end

"""
    constraint_relaxation!(cost, mask, row_covered, col_covered, Δrow, Δcol, rowSTAR, row2colSTAR)
Step 6: Add the value found in Step 4 to every element of each covered row, and subtract it from every element of each uncovered column. 
Return to Step 4 without altering any stars, primes, or covered lines.
"""
function constraint_relaxation!(
    cost::AbstractMatrix, mask::SparseMatrixCSC, row_covered::BitVector, col_covered::BitVector, Δrow::AbstractVector, Δcol::AbstractVector,
    rowSTAR::BitVector, row2colSTAR::Dict
    )

    min_value, min_locations = find_smallest_uncovered(cost, row_covered, col_covered, Δrow, Δcol)

    # Equivalent to: Subtract min_value from every unmarked element and add it to every element covered by two lines. 
    for (i, is_covered) in enumerate(row_covered)
        if (is_covered)
            Δrow[i] += min_value
        end
    end
    for (j, is_covered) in enumerate(col_covered)
        if (!is_covered)
            Δcol[j] -= min_value
        end
    end
    for loc in min_locations
        mask[loc] = ZERO
    end
    # remove any zeros covered by 2 lines
    reduce_old_zeros!(mask, row_covered, col_covered, rowSTAR, row2colSTAR)

    FIND_ALTERNATIVES
end

function find_smallest_uncovered(
    cost::AbstractMatrix, row_covered::BitVector, col_covered::BitVector, Δrow::AbstractVector, Δcol::AbstractVector)
    # This is the main bottleneck 
    # Searching through all elements is approximately an O(n*m) operation.
    min_value = typemax(Float64)
    min_locations = CartesianIndex[] 

    uncovered_cols = [j for (j, covered) in enumerate(col_covered) if !covered]
    uncovered_rows = [i for (i, covered) in enumerate(row_covered) if !covered]
    for j in uncovered_cols
        for i in uncovered_rows
            @inbounds c = cost[i, j] + Δrow[i] + Δcol[j]
            if c <= min_value
                if (c != min_value)
                    min_value = c
                    empty!(min_locations)
                end
                push!(min_locations, CartesianIndex(i, j))
            end
        end
    end
    min_value, min_locations
end

function reduce_old_zeros!(
    mask::SparseMatrixCSC, row_covered::BitVector, col_covered::BitVector, 
    rowSTAR::BitVector, row2colSTAR::Dict
    )
    rows = rowvals(mask)
    for j in axes(mask, 2)
        if col_covered[j]
            for r in nzrange(mask, j)
                i = rows[r]
                if row_covered[i]
                    if mask[i, j] == STAR
                        rowSTAR[i] = false
                        delete!(row2colSTAR, i)
                    end
                    mask[i, j] = NONZERO
                end
            end
        end
    end
    dropzeros!(mask)
end
