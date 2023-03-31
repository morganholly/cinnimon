import types
import std/[math]

const e_math = 2.7182818284590452353602874713526624977572470936999595749669676277

proc add* (graph: var Graph, node: GraphNode): Graph =
    graph.nodes.add(node)
    result = graph

proc connect* (graph: var Graph, n1, n2: var GraphNode, p1, p2: int, component: ComponentVariant, spring: float = 1): Graph =
    var spring = SpringState(rest_length: spring, current_length: spring, force: 0.0, stiffness: 2)
    var gc1 = GraphConnection(component: component, from_pin: p1, to_pin: p2, spring: spring)
    var gc2 = GraphConnection(component: component, from_pin: p2, to_pin: p1, spring: spring)
    n1.connections.add(gc1)
    n2.connections.add(gc2)
    graph.connections.add([gc1, gc2])
    result = graph

proc lerp (x, y, mix: float): float =
    result = mix * y + (1 - mix) * x

proc spring_force* (spring: var SpringState, skew: float): SpringState =
    let delta = spring.current_length - spring.rest_length
    let clamped = min(max((delta * 0.5) + 0.75, 0), 1)
    let clamped_nl = 2 * clamped * clamped
    let phase = lerp(
        lerp(
            skew * delta,
            -skew * delta * delta,
            pow(e_math, skew * skew - 10)
        ),
        delta,
        if (delta * 0.5) < -0.25:
            clamped_nl
        else:
            1 - clamped_nl
    )
    let scaled_phase = phase * pow(e_math, spring.stiffness - 8) * spring.rest_length
    spring.force = scaled_phase * scaled_phase * toFloat(sgn(-delta))
    result = spring

proc direct_connections* (n1, n2: GraphNode): int =
    result = 0
    for c in n1.connections:
        if c.component.connections[c.to_pin] == n2:
            result += 1
