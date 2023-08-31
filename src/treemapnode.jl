struct TreeMapNode{M}
    weight::Float64
    children::Vector{TreeMapNode{M}}
    metadata::M
end

function TreeMapNode(children::AbstractVector, metadata = nothing)
    weight = sum(x -> x.weight, children, init = 0.0)
    TreeMapNode(weight, children, metadata)
end

function Base.show(io::IO, t::TreeMapNode)
    print(io, typeof(t))
    print(io, "(weight: $(t.weight), children: $(length(t.children)))")
end

TreeMapNode(weight::Float64, metadata = nothing) = TreeMapNode{Nothing}(weight, TreeMapNode{Nothing}[], metadata)

function rand_treemap(depth)
    depth == 0 && return TreeMapNode(rand() + 0.2)
    TreeMapNode([rand_treemap(depth - 1) for i in 1:2])
end

isleaf(t::TreeMapNode) = isempty(t.children)
