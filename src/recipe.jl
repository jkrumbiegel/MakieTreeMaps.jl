Makie.@recipe(TreeMap) do scene
    Makie.Attributes(
        inspectable = true,
        shininess = 0,
        diffuse = Makie.Vec3f(1.0),
        specular = Makie.Vec3f(0),
        labeller = (indexstack, node) -> "$indexstack",
        to_colorvalue = (node) -> rand(1:7),
    )
end

function Makie.plot!(tm::TreeMap)
    node::TreeMapNode = tm[1][]

    vertices = Makie.Point3f[]
    faces = GeometryBasics.QuadFace{GeometryBasics.OffsetInteger{-1, UInt32}}[]
    colors = Float32[]
    indexstacks = Vector{Int}[]
    rectangles = Makie.Rect2f[]

    rectstack = Pair{Makie.Rect2f,Bool}[Makie.Rect2f(0.0, 0.0, 1.0, 1.0) => true]
    indexstack = Int[1]

    function visit_node!(vertices, faces, colors, rectangles, node::TreeMapNode, to_colorvalue::Function)

        cr, current_direction = rectstack[end]
        
        offset = 0.0
        for (i, childnode) in enumerate(node.children)
            childfraction = childnode.weight / node.weight
            childrect = if current_direction
                Makie.Rect2f(
                    cr.origin[1] + cr.widths[1] * offset,
                    cr.origin[2],
                    cr.widths[1] * childfraction,
                    cr.widths[2]
                )
            else
                Makie.Rect2f(
                    cr.origin[1],
                    cr.origin[2] + cr.widths[2] * offset,
                    cr.widths[1],
                    cr.widths[2] * childfraction
                )
            end

            direction = childrect.widths[1] > childrect.widths[2]

            if i == 1
                push!(rectstack, childrect => direction)
                push!(indexstack, i)
            else
                rectstack[end] = childrect => direction
                indexstack[end] = i
            end
            
            if isleaf(childnode)
                colorval = to_colorvalue(childnode)
                add_bump_mesh!(vertices, faces, colors, rectangles, indexstacks, rectstack, 10, indexstack, colorval)
            else
                visit_node!(vertices, faces, colors, rectangles, childnode, to_colorvalue)
            end

            offset += childfraction
        end
        pop!(rectstack)
        pop!(indexstack)
        return
    end

    visit_node!(vertices, faces, colors, rectangles, node, tm.to_colorvalue[])

    m = Makie.GeometryBasics.Mesh(vertices, faces)
    max_z = maximum(x -> x[3], vertices)

    msh = Makie.mesh!(tm, m; color = colors, shininess = 0, diffuse = Makie.Vec3f(1.0), specular = Makie.Vec3f(0))
    Makie.scale!(msh, Makie.Vec3f(1, 1, 1/max_z))

    tm[:_metadata] = (; rectangles, indexstacks, vertices)
    
    return tm
end

function add_bump_mesh!(vertices, faces, colors, rectangles, indexstacks, rectstack, res::Int, indexstack, colorval)
    r, d = rectstack[end]

    x1 = r.origin[1]
    x2 = x1 + r.widths[1]
    y1 = r.origin[2]
    y2 = y1 + r.widths[2]

    nv = length(vertices)

    this_indexstack = copy(indexstack)

    for x in range(x1, x2, length = res)
        for y in range(y1, y2, length = res)
            z = 0.0
            for (_r, _dir) in rectstack
                _x1 = _r.origin[1]
                _x2 = _x1 + _r.widths[1]
                _y1 = _r.origin[2]
                _y2 = _y1 + _r.widths[2]
                w = _x2 - _x1
                h = _y2 - _y1
                
                if _dir
                    dz =  4 / w * (x - _x1) * (_x2 - x)
                else
                    dz = 4 / h * (y - _y1) * (_y2 - y)
                end
                z += dz
            end
            push!(vertices, Makie.Point3f(x, y, z))
            push!(indexstacks, this_indexstack)
            push!(colors, colorval)
            push!(rectangles, rectstack[end][1])
        end
    end

    fcs = Makie.decompose(GeometryBasics.QuadFace{GeometryBasics.GLIndex}, Makie.Tesselation(Makie.Rect(0, 0, 1, 1), (res, res)))
    fcs = [reverse(f) .+ nv for f in fcs]

    append!(faces, fcs)
    return
end

function Makie.show_data(inspector::Makie.DataInspector, plot::TreeMap, idx, ::Makie.Mesh)
    # inspector.attributes holds some attributes relevant to indicators and is
    # used as a cache for indicator observables
    a = inspector.attributes
    tt = inspector.plot
    scene = Makie.parent_scene(plot)

    rect = bbox = plot._metadata[].rectangles[idx]
    indexstack = bbox = plot._metadata[].indexstacks[idx]

    proj_pos = Makie.shift_project(scene, plot, Makie.to_ndim(Makie.Point3f, Makie.mouseposition(scene), 0))
    Makie.update_tooltip_alignment!(inspector, proj_pos)

    # We only want to mark the rectangle if that setting is enabled
    if a.enable_indicators[]
        # Get the relevant rectangle
        bbox = rect

        # If we haven't yet created an indicator create it
        if inspector.selection != plot
            # clear old indicators
            Makie.clear_temporary_plots!(inspector, plot)

            # Create the new indicator using some settings from `DataInspector`.
            p = Makie.wireframe!(
                scene, bbox, color = a.indicator_color,
                strokewidth = a.indicator_linewidth, linestyle = a.indicator_linestyle,
                visible = a.indicator_visible, inspectable = false,
            )

            # tooltips are pushed forward a certain amount to make sure they're
            # drown on top of other things. This indicator should also be pushed
            # forward that much
            Makie.translate!(p, Makie.Vec3f(0, 0, 0.95 * a.depth[]))

            # Keep track of the indicator plot
            push!(inspector.temp_plots, p)

        # If we have already created an indicator plot we just need to update 
        # it. In this case we only need to update the rectangle.
        elseif !isempty(inspector.temp_plots)
            p = inspector.temp_plots[1]
            p[1][] = bbox
        end

        # Moving away from a plot will automatically set this to false, so we 
        # always need to set it to true.
        a.indicator_visible[] = true
    end

    node = plot[1][]
    tt.text[] = plot.labeller[](indexstack, node)
    tt.visible[] = true

    return true
end
