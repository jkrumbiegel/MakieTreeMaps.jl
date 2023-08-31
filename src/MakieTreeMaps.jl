module MakieTreeMaps

import Makie
import Makie.GeometryBasics

export TreeMapNode
export treemap, treemap!

include("treemapnode.jl")
include("recipe.jl")

end
