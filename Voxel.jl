
module Voxel

using CSFML
using CSFML.LibCSFML
export newVoxel

const AIR = 0
const STONE = 1
const SAND = 2

const airColor = sfColor_fromRGBA(0, 0, 0, 255)
const sandColor = sfColor_fromRGBA(254, 232, 176, 255)
function newVoxel(type)
    color = type == AIR ? airColor : sandColor
    return particle(color, type)
end

mutable struct particle
    color::sfColor
    type::Int32
    # vx::Float32
    # vy::Float32
    # r::Float32
    # g::Float32
    # b::Float32
    # a::Float32
    # lifetime:::Float32
    # mass::Float32
end

end



