"""
    Permutation(data)
    Permutation(1:n)
    Permutation(n)

Returns an iterator for all the permutations of vector with `length` n.
For an array of all permutations, use `collect(Permutation(n))`. 
Does not cater for repeats.
"""
struct Permutation{T} 
    data::T
end


Base.length(perm::Permutation) = prod(1:length(perm.data)) # overflows for length > 25
Base.IteratorSize(perm::Permutation) = Base.HasLength()

Permutation(v::UnitRange) = Permutation(collect(v))
Permutation(n::Int) = Permutation(collect(1:n))

mutable struct PermutationState
    data::Vector{Int}
    stack::Vector{Int}
    idx::Int
end

function Base.iterate(perm::Permutation) 
    (perm.data, PermutationState(collect(1:length(perm.data)), ones(Int, length(perm.data)), 2))
end

function Base.iterate(perm::Permutation, state::PermutationState)
    # Heap's algorithm
    stack = state.stack
    while state.idx <= length(state.data)
        if stack[state.idx] < state.idx
            if (state.idx % 2 != 0)
                swap!(state.data, 1, state.idx)
            else
                swap!(state.data, stack[state.idx], state.idx)
            end
            stack[state.idx] += 1
            state.idx = 1
            out = [perm.data[i] for i in state.data]
            return (out, state)
        else
            stack[state.idx] = 1
            state.idx += 1
        end
    end
    nothing
end

function swap!(v::AbstractVector, i::Int, j::Int)
    temp = v[i]
    v[i] = v[j]
    v[j] = temp
end