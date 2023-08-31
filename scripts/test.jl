using MakieTreeMaps
using GLMakie
GLMakie.activate!(float = true)

function modify_lights!(ax)
    ax.scene.lights[1].position[] = Point3f(0, 0, 1000)
    ax.scene.lights[1].radiance[] = RGBf(0.85)
    ax.scene.lights[2].color[] = RGBf(0.05,0.05,0.05)
    return
end

##
using Random
Random.seed!(123)
f = Figure(figure_padding = 0)
ax = Axis(f[1, 1])
tightlimits!(ax)
hidedecorations!(ax)
modify_lights!(ax)
tmp = treemap!(ax, MakieTreeMaps.rand_treemap(5))
insp = DataInspector(f)
f

##

function filesize_treemap(root, folder = ".")
    children = TreeMapNode{String}[]
    for path in readdir(joinpath(root, folder))
        startswith(path, ".") && continue
        path == "artifacts" && continue
        p = joinpath(root, folder, path)
        islink(path) && continue
        if isfile(p)
            push!(children, TreeMapNode(max(filesize(p), 1.0), TreeMapNode{String}[], path))
        elseif isdir(p)
            tm = filesize_treemap(joinpath(root, folder), path)
            if !MakieTreeMaps.isleaf(tm)
                push!(children, tm)
            end
        end
    end
    sort!(children, by = x -> x.weight, rev = true)
    TreeMapNode(children, folder)
end

tm = filesize_treemap(expanduser("~/.julia/"))

##

function format_bytes(bytes)
    if bytes < 1024
        return "$bytes B"
    elseif bytes < 1024^2
        return "$(round(bytes / 1024, digits=2)) kB"
    elseif bytes < 1024^3
        return "$(round(bytes / (1024^2), digits=2)) MB"
    elseif bytes < 1024^4
        return "$(round(bytes / (1024^3), digits=2)) GB"
    else
        return "$(round(bytes / (1024^4), digits=2)) TB"
    end
end

f = Figure(figure_padding = 0)
ax = Axis(f[1, 1])
hidedecorations!(ax)
modify_lights!(ax)

treemap!(ax, tm;
    labeller = function (indexstack, node)
        nodes = typeof(node)[]

        local curnode
        for (i, index) in enumerate(indexstack)
            thisnode = i == 1 ? node : curnode.children[index]
            push!(nodes, thisnode)
            curnode = thisnode
        end

        join([x.metadata for x in nodes], "/") * " $(format_bytes(curnode.weight))"
    end,
    to_colorvalue = function (node)
        if endswith(node.metadata, ".jl")
            1
        elseif endswith(node.metadata, ".ji")
            2
        elseif endswith(node.metadata, ".png")
            3
        elseif endswith(node.metadata, ".dylib")
            4
        else
            5
        end
    end
)
tightlimits!(ax)
DataInspector(f)
f