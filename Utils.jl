module Utils



export applyBetween

# for now assume p1 and p2 are 2d [x,y]


function applyBetween(p1::Vector, p2::Vector, f)
    if (p1 == p2)
        f(p1)
        return
    end
    x1, y1 = p1
    x2, y2 = p2

    dx = x2 - x1
    dy = y2 - y1
    dxIsLarger = abs(dx) > abs(dy)

    xModifier = dx < 0 ? -1 : 1
    yModifier = dy < 0 ? -1 : 1

    longerSideLength = dxIsLarger ? abs(dx) : abs(dy)
    shorterSideLength = dxIsLarger ? abs(dy) : abs(dx)
    slope = shorterSideLength == 0 || longerSideLength == 0 ? 0 : shorterSideLength / longerSideLength

    for i in 0:longerSideLength
        if (dxIsLarger)
            f([x1 + i * xModifier, y1 + round(Int, i * slope) * yModifier])
        else
            f([x1 + round(Int, i * slope) * xModifier, y1 + i * yModifier])
        end
    end
end


# function getVoxelColor(type)
#     type == Voxel.AIR ? Voxel.airColor :
#     type == Voxel.STONE ? Voxel.stoneColor :
#     type == Voxel.SAND ? Voxel.sandColor :
#     _ => sfColor_fromRGBA(0, 0, 0, 255)

# end

end