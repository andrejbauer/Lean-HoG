import LeanHoG.LoadGraph
import LeanHoG.Widgets
import LeanHoG.Tactic.SearchDSL
-- import LeanHoG.Tactic.Basic

namespace LeanHoG

-- Load the cycle on 7 vertices from JSON file
load_graph Cycle7 "examples/cycle7.json"

#visualizeGraph Cycle7

-- Check that Cycle7 is connected
#check Cycle7.is_connected

-- Load the K_{2,2,2,2,2} from "cube-5.json"
load_graph Cube5 "examples/cube5.json"

-- Check that Cube5 is connected
#check Cube5.is_connected

-- Discrete graph on two points
load_graph Two "examples/two.json"
#check Two.is_disconnected

-- Load the disjoint union of 3- and 4-cycle
load_graph Cow "examples/cycle3-cycle4.json"
#check Cow.is_disconnected

load_graph Petersen "build/graphs/660.json"
#visualizeHamiltonianPath Petersen

#search_hog hog{(minimumDegree < numberOfVertices / 2)}

end LeanHoG
