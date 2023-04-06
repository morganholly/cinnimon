import boxy, opengl, windy, vmath
import graph, types
import std/[times, math, tables]

proc arrow_draw* (boxy: Boxy, key: string, tail: Vec2, head: Vec2, thickness: float32 = 1): void =
    let angle = arctan2(tail.x - head.x, tail.y - head.y)
    let distance = sqrt(
        (head.x - tail.x) * (head.x - tail.x) +
        (head.y - tail.y) * (head.y - tail.y))
    var scale = vec2(thickness, distance / boxy.entries[key].size.vec2.y)
    # let scaled_width = scale * 0.5 * boxy.entries[key].size.vec2.x
    boxy.saveTransform()
    boxy.translate(tail)
    boxy.rotate(angle)
    boxy.scale(scale)
    boxy.translate(vec2(-0.5 * boxy.entries[key].size.vec2.x, -boxy.entries[key].size.vec2.y))
    boxy.drawImage(key, pos = vec2(0, 0), color(1, 1, 1, 1))
    boxy.restoreTransform()

proc hslider_draw* (boxy: Boxy, position: Vec2, length, slider: float): void =
    boxy.saveTransform()
    boxy.arrow_draw("sliderbar_middle",
        position + vec2(boxy.entries["sliderbar_end"].size.vec2.x - 1, boxy.entries["sliderbar_end"].size.vec2.y * 0.5),
        position + vec2(boxy.entries["sliderbar_end"].size.vec2.x + 1 + length, boxy.entries["sliderbar_end"].size.vec2.y * 0.5))
    boxy.drawImage("sliderbar_end", position, color(1, 1, 1, 1))
    boxy.translate(position + vec2(length + boxy.entries["sliderbar_end"].size.vec2.x * 2, 0.0))
    boxy.scale(vec2(-1, 1))
    boxy.drawImage("sliderbar_end", vec2(0, 0), color(1, 1, 1, 1))
    boxy.restoreTransform()

let windowSize = ivec2(3000, 2000)

let window = newWindow("Springy", windowSize, vsync = true)
makeContextCurrent(window)

loadExtensions()

let bxy = newBoxy()

# Load the images.
bxy.addImage("bg", readImage("bg.png"))
bxy.addImage("star1", readImage("star1.png"))
bxy.addImage("bluecircle", readImage("bluecircle.png"))
bxy.addImage("arrow", readImage("arrow.png"))
bxy.addImage("wavy", readImage("wavy.png"))
bxy.addImage("sliderbar_end", readImage("sliderbar_end.png"))
bxy.addImage("sliderbar_middle", readImage("sliderbar_middle.png"))

var g = Graph(nodes: @[], connections: @[])
var gn1 = GraphNode(connections: @[], position: vec2(5.0, 0.0), velocity: vec2(0.0, 0.0))
var gn2 = GraphNode(connections: @[], position: vec2(20.0, 40.0), velocity: vec2(0.0, 0.0))
var gn3 = GraphNode(connections: @[], position: vec2(30.0, 10.0), velocity: vec2(0.0, 0.0))
var gn4 = GraphNode(connections: @[], position: vec2(40.0, 5.0), velocity: vec2(0.0, 0.0))
var gn5 = GraphNode(connections: @[], position: vec2(-30.0, -10.0), velocity: vec2(0.0, 0.0))
var gn6 = GraphNode(connections: @[], position: vec2(-5.0, -20.0), velocity: vec2(0.0, 0.0))
var gn7 = GraphNode(connections: @[], position: vec2(-5.0, -20.0), velocity: vec2(0.0, 0.0))
var gn8 = GraphNode(connections: @[], position: vec2(-5.0, -20.0), velocity: vec2(0.0, 0.0))
var gn9 = GraphNode(connections: @[], position: vec2(-5.0, -20.0), velocity: vec2(0.0, 0.0))
var gnmouse = GraphNode(connections: @[], position: vec2(10.0, 0.0), velocity: vec2(0.0, 0.0))
var gncenter = GraphNode(connections: @[], position: vec2(10.0, 0.0), velocity: vec2(0.0, 0.0))

var rest_dist = 20.0

discard g.add(gn1).add(gn2).add(gn3).add(gn4).add(gn5).add(gn6).add(gn7).add(gn8).add(gn9) #.add(gnmouse)
discard g.connect(gn1, gn2, 0, 1, ckRes, @[10.0], rest_dist)
        .connect(gn2, gn3, 0, 1, ckRes, @[120.0], rest_dist)
        .connect(gn3, gn4, 0, 1, ckRes, @[800.0], rest_dist)
        .connect(gn4, gn5, 0, 1, ckRes, @[2000.0], rest_dist)
        .connect(gn5, gn6, 0, 1, ckRes, @[2000.0], rest_dist)
        .connect(gn6, gn7, 0, 1, ckRes, @[2000.0], rest_dist)
        .connect(gn7, gn8, 0, 1, ckRes, @[2000.0], rest_dist)
        .connect(gn8, gn9, 0, 1, ckRes, @[2000.0], rest_dist)
        .connect(gn9, gnmouse, 0, 1, ckRes, @[90.0], rest_dist)
        .connect(gn1, gncenter, 0, 1, ckRes, @[100.0], rest_dist)

var gbackup: Graph
deepCopy(gbackup, g)

var frame: int
var scale = 1.0
var time1 = 0.0
var time2 = 0.0

# Called when it is time to draw a new frame.
window.onFrame = proc() =
    time1 = time2
    time2 = cpuTime()
    # Clear the screen and begin a new frame.
    bxy.beginFrame(window.size)

    bxy.drawImage("bg", rect = rect(vec2(0, 0), window.size.vec2))

    let center = window.size.vec2 / 2
    gnmouse.position = window.mousePos.vec2 - center
    gncenter.position = vec2(0, 0)
    g.update_springs().apply_spring_forces_to_velocity().apply_node_forces().apply_velocities(1)
    # echo(gn1.position)
    # echo(gnmouse.position)

    for c in g.connections:
        bxy.arrow_draw("wavy", center + c.component.connections[c.to_pin].position, center + c.component.connections[c.from_pin].position)
        # bxy.arrow_draw("arrow", center + c.component.connections[c.from_pin].position, center + (c.component.connections[c.from_pin].position - c.component.connections[c.to_pin].position) * c.spring.force + c.component.connections[c.from_pin].position)

    for n in g.nodes:
        bxy.drawImage("bluecircle", center + n.position, angle = 0)
        bxy.arrow_draw("arrow", center + n.position, center + n.position + vec2(10, 10) * n.velocity)

    window.onButtonPress = proc(button: Button) =
        echo "onButtonPress ", button
        echo "down: ", window.buttonDown[button]
        echo "pressed: ", window.buttonPressed[button]
        echo "released: ", window.buttonReleased[button]
        echo "toggle: ", window.buttonToggle[button]
        if (button == KeyR) and window.buttonDown[button]:
            deepCopy(g, gbackup)
            # discard g.connect(gn5, gnmouse, 0, 1, ckRes, @[100.0], 500)

    bxy.hslider_draw(vec2(0.0, 0.0), 64.0, 0.0)
    bxy.hslider_draw(vec2(0.0, 64.0), 256.0, 0.0)

    # End this frame, flushing the draw commands.
    bxy.endFrame()
    # Swap buffers displaying the new Boxy frame.
    window.swapBuffers()
    inc frame

while not window.closeRequested:
    pollEvents()