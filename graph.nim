import types

proc add* (graph: var Graph, node: GraphNode): Graph =
    graph.nodes.add(node)
    return graph

proc connect* (graph: var Graph, n1, n2: var GraphNode, p1, p2: int, component: ComponentVariant, spring: float = 1): Graph =
    var spring = SpringState(rest_length: spring, current_length: spring)
    var gc1 = GraphConnection(component: component, from_pin: p1, to_pin: p2, spring: spring)
    var gc2 = GraphConnection(component: component, from_pin: p2, to_pin: p1, spring: spring)
    n1.connections.add(gc1)
    n2.connections.add(gc2)
    graph.connections.add([gc1, gc2])
    return graph
