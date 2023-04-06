import types
import vmath
import std/[math]

const e_math = 2.7182818284590452353602874713526624977572470936999595749669676277

proc add* (graph: var Graph, node: GraphNode): var Graph =
    graph.nodes.add(node)
    result = graph

proc connect* (graph: var Graph, n1, n2: var GraphNode, p1, p2: int, component: ComponentVariant, spring: float = 1): var Graph =
    var spring = SpringState(rest_length: spring, current_length: spring, force: 0.0, stiffness: 0.05)
    var gc1 = GraphConnection(component: component, from_pin: p1, to_pin: p2, spring: spring)
    var gc2 = GraphConnection(component: component, from_pin: p2, to_pin: p1, spring: spring)
    n1.connections.add(gc1)
    n2.connections.add(gc2)
    graph.connections.add([gc1])
    result = graph

proc connect* (graph: var Graph, n1, n2: var GraphNode, p1, p2: int, kind: ComponentKind, values: seq[float], spring: float = 1): var Graph =
    var spring = SpringState(rest_length: spring, current_length: spring, force: 0.0, stiffness: 0.05)
    var cvconnections = newSeq[GraphNode](componentConnections(kind))
    cvconnections[p1] = n1
    cvconnections[p2] = n2
    var component = ComponentVariant(connections: cvconnections, values: values, kind: kind)
    var gc1 = GraphConnection(component: component, from_pin: p1, to_pin: p2, spring: spring)
    var gc2 = GraphConnection(component: component, from_pin: p2, to_pin: p1, spring: spring)
    n1.connections.add(gc1)
    n2.connections.add(gc2)
    graph.connections.add([gc1])
    result = graph

proc lerp (x, y, mix: float): float =
    result = mix * y + (1 - mix) * x

proc spring_force_fancy_broken* (spring: var SpringState, skew: float = 1.5): var SpringState =
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
    let scaled_phase = phase * pow(e_math, spring.stiffness - 8) # * spring.rest_length
    spring.force = scaled_phase * scaled_phase * toFloat(sgn(-delta))
    result = spring

proc spring_force* (spring: var SpringState, skew: float = 1): var SpringState =
    let delta = spring.current_length - spring.rest_length
    spring.force = -((((toFloat(sgn(-delta)) * 0.5 + 0.5) * -skew) + spring.stiffness) * delta)
    result = spring

proc spring_length* (conn: var GraphConnection): var GraphConnection =
    conn.spring.current_length = dist(conn.component.connections[conn.to_pin].position, conn.component.connections[conn.from_pin].position)
    result = conn

proc direct_connections* (n1, n2: GraphNode): int =
    result = 0
    for c in n1.connections:
        if c.component.connections[c.to_pin] == n2:
            result += 1

proc distsq (n1, n2: GraphNode): float =
    # let xdif = n1.position.x - n2.position.x
    # let ydif = n1.position.y - n2.position.y
    let diff = n1.position - n2.position
    result = diff.x * diff.x + diff.y * diff.y

proc dist (n1, n2: GraphNode): float =
    result = sqrt(distsq(n1, n2))

proc dist (node: GraphNode, vec: Vec2): float =
    let diff = node.position - vec
    result = diff.x * diff.x + diff.y * diff.y

proc node_force* (n1, n2: var GraphNode, strength, spread, force_limit: float): void =
    let dist = dist(n1, n2)
    if dist < 0.000001:
        return
    let exp = pow(e_math, spread - 5)
    let gaussish = exp / (dist + exp)
    let invx = (strength * exp) / (dist + force_limit)
    let force = lerp(
        -invx,
        invx,
        gaussish
    )
    # let fx = (n1.position[0] - n2.position[0]) * (force * force) / distsq
    # let fy = (n1.position[1] - n2.position[1]) * (force * force) / distsq
    # n1.velocity[0] += fx
    # n1.velocity[1] += fy
    # n2.velocity[0] -= fx
    # n2.velocity[1] -= fy
    let directed = (n1.position - n2.position) * force / dist
    n1.velocity += directed
    n2.velocity -= directed

proc update_springs* (graph: var Graph): var Graph =
    for c in graph.connections.mitems:
        discard c.spring_length()
        discard spring_force(c.spring)
    result = graph

proc apply_spring_forces_to_velocity* (graph: var Graph): var Graph =
    for n in graph.nodes.mitems:
        for c in n.connections:
            # n.velocity[0] += (n.position[0] - otherpos[0]) * (forcesq) / distsq
            # n.velocity[1] += (n.position[1] - otherpos[1]) * (forcesq) / distsq
            n.velocity +=
                (n.position - c.component.connections[c.to_pin].position) * (c.spring.force) / (dist(n, c.component.connections[c.to_pin]) + 0.00001)
    result = graph

proc apply_node_forces* (graph: var Graph): var Graph =
    for i in 0..<len(graph.nodes):
        for j in i..<len(graph.nodes):
            node_force(graph.nodes[i], graph.nodes[j], 5, 10, 5)
    result = graph

proc apply_velocities* (graph: var Graph, dt: float): void = # seq[array[2, Vec2]] =
    # result = @[]
    for n in graph.nodes.mitems:
        # n.position[0] += n.velocity[0] * dt
        # n.position[1] += n.velocity[1] * dt
        # result.add([n.position, n.velocity])
        n.position += n.velocity * dt
        n.velocity *= 0.75
