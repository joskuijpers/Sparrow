# Sparrow (cancelled)

An attempt to make a game engine in Swift. I ended up getting blocked and disinterested.

Has 2 binary coder/decoders, one that safely supports backwards compatibility (by keeping track of keys), and one that is super efficient.

The test game has Metal shaders with tiled forward+ shading PBR implemented. The PBR is missing IBL so it is not complete and I think it is also not correct. The tiled shading works though.

The ECS project is a fork of https://github.com/fireblade-engine/ecs with a whole bunch of changes. See https://github.com/fireblade-engine/ecs/blob/master/LICENSE for the license.

All the other code is available under MIT. Feel free to let me know if you use any of it, I love to see where things end up.
