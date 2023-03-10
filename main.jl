using CSFML
using CSFML.LibCSFML

include("Utils.jl")
include("Voxel.jl")
using .Voxel: newVoxel
using .Utils: applyBetween

# enums of particle types, sand, stone, water, etc
const AIR = 0
const STONE = 1
const SAND = 2
# const WATER = 3

selectedBlock = SAND
windowWidth = 640
windowHeight = 480
leftPressed = false
prevPosition = nothing;
cursorSize = 0

# TODO figure out how I want to handle resizing and map size in general

board = [[newVoxel(AIR) for i in 0:windowWidth-1] for j in 0:windowHeight-1]
moveableMap = Dict()

function getBoardColors(board)
    flatBoard = collect(Iterators.flatten(board))
    boardColors = map(p -> p.color, flatBoard)
    return boardColors
end

imageBuffer = sfImage_createFromPixels(windowWidth, windowHeight, getBoardColors(board))
@assert imageBuffer != C_NULL

mode = sfVideoMode(windowWidth, windowHeight, 32)
VSYNC_FRAME_COUNT = 60;

window = sfRenderWindow_create(mode, "sandy", sfResize | sfClose, C_NULL)
@assert window != C_NULL

sprite = sfSprite_create()

font = sfFont_createFromFile(joinpath(dirname(pathof(CSFML)), "..", "examples", "Roboto-Bold.ttf"))
@assert font != C_NULL

event_ref = Ref{sfEvent}()

selectedBlockText = sfText_create()
sfText_setFont(selectedBlockText, font)
sfText_setCharacterSize(selectedBlockText, 30)

text = sfText_create()
sfText_setFont(text, font)
sfText_setCharacterSize(text, 30)

clock = sfClock_create()
lastTime = 0.0

function updateImageBuffer()
    # TODO update board based on chunks for performance
    global imageBuffer = sfImage_createFromPixels(windowWidth, windowHeight, getBoardColors(board))
end

function handleResize()
    global windowWidth = sfRenderWindow_getSize(window).x
    global windowHeight = sfRenderWindow_getSize(window).y
    global imageBuffer = sfImage_createFromColor(windowWidth, windowHeight, sfColor_fromRGBA(255, 45, 0, 255))
    @assert imageBuffer != C_NULL
    # reset the view so mouse clicks come in correctly with new screen size
    sfRenderWindow_setView(window, sfView_createFromRect(sfFloatRect(0, 0, windowWidth, windowHeight)))
    return true
end

function updateClickedPixel(prevPosition)
    mousePos = sfMouse_getPositionRenderWindow(window)
    if mousePos.x < 0 || mousePos.x >= windowWidth || mousePos.y < 0 || mousePos.y >= windowHeight
        return
    end

    if prevPosition === nothing
        global prevPosition = mousePos
    else

    end

    function setPixel(point)
        x = point[1]
        y = point[2]
        if x < 0 || x >= windowWidth || y < 0 || y >= windowHeight
            return
        end
        board[y+1][x+1] = newVoxel(selectedBlock)
        if (selectedBlock == SAND)
            moveableMap[[y + 1, x + 1]] = SAND
        end
    end

    function drawAt(point)
        starts = point .- cursorSize
        ends = point .+ cursorSize
        for i in starts[1]:ends[1]
            for j in starts[2]:ends[2]
                setPixel([i, j])
            end
        end
    end

    applyBetween([prevPosition.x, prevPosition.y], [mousePos.x, mousePos.y], drawAt)

    global prevPosition = mousePos
end

function physicsTick(board)
    # iterate over moveableMap and move particles down if air below them
    for (i, j) in keys(moveableMap)
        if i < windowHeight
            down1 = board[i+1][j]
            # TODO check against swappable blocks instead of air
            if down1.type == AIR
                board[i+1][j] = board[i][j]
                board[i][j] = down1
                moveableMap[[i + 1, j]] = moveableMap[[i, j]]
                delete!(moveableMap, [i, j])
            end
        end
    end
end

function handleKeys(event::sfEvent)
    if (event.key.code == sfKeyNum1)
        global selectedBlock = SAND
    end
    if (event.key.code == sfKeyNum2)
        global selectedBlock = STONE
    end
    if (event.key.code == sfKeyNum3)
        global selectedBlock = AIR
    end
    if (event.key.code == sfKeyUp)
        global cursorSize += 1
        println("cursorSize:", cursorSize)
    end
    if (event.key.code == sfKeyDown)
        global cursorSize -= 1
        println("cursorSize:", cursorSize)
    end
    # event_ref.x.type == sfKeyNum3 && 
end

function mouseHandler(event::sfEvent)
    isLeft = sfMouseLeft == event.mouseButton.button
    # rightPress = sfMouseRight == event.mouseButton.button
    if event.type == sfEvtMouseButtonPressed && isLeft
        updateClickedPixel(prevPosition)
        global leftPressed = true
    end

    if event.type == sfEvtMouseMoved && leftPressed
        updateClickedPixel(prevPosition)
    end

    if event.type == sfEvtMouseButtonReleased && isLeft
        global leftPressed = false
        global prevPosition = nothing
    end
end

lastPhysicsTick = 0.0
while Bool(sfRenderWindow_isOpen(window))

    currentTime = sfTime_asSeconds(sfClock_getElapsedTime(clock))
    dt = (currentTime - lastTime)
    if (dt < 1.0 / VSYNC_FRAME_COUNT)
        continue
    end
    fps = 1.0 / dt
    global lastTime = currentTime

    # process events
    while Bool(sfRenderWindow_pollEvent(window, event_ref))
        # close window : exit
        event_ptr = Base.unsafe_convert(Ptr{sfEvent}, event_ref)
        # close window : exit
        GC.@preserve event_ref begin
            ty = unsafe_load(event_ptr.type)
            ty == sfEvtClosed && sfRenderWindow_close(window)
            ty == sfEvtResized && handleResize() && println("Trigger sfEvtResized.")
            ty == sfEvtLostFocus && println("Trigger sfEvtLostFocus.")
            ty == sfEvtGainedFocus && println("Trigger sfEvtGainedFocus.")
            ty == sfEvtTextEntered && println("Trigger sfEvtTextEntered: $(unsafe_load(event_ptr.text).unicode)")
            ty == sfEvtKeyPressed && println("Trigger sfEvtKeyPressed: $(unsafe_load(event_ptr.key).code)")
            ty == sfEvtKeyReleased && println("Trigger sfEvtKeyReleased: $(unsafe_load(event_ptr.key).code)")
            ty == sfEvtMouseWheelMoved && println("Trigger sfEvtMouseWheelMoved: $(unsafe_load(event_ptr.mouseWheel).x), $(unsafe_load(event_ptr.mouseWheel).y)")
            ty == sfEvtMouseWheelScrolled && println("Trigger sfEvtMouseWheelScrolled: $(unsafe_load(event_ptr.mouseWheelScroll).wheel)")
            ty == sfEvtMouseButtonPressed && println("Trigger sfEvtMouseButtonPressed: $(unsafe_load(event_ptr.mouseButton).button)")
            ty == sfEvtMouseButtonReleased && println("Trigger sfEvtMouseButtonReleased: $(unsafe_load(event_ptr.mouseButton).x), $(unsafe_load(event_ptr.mouseButton).y)")
            ty == sfEvtMouseMoved && println("Trigger sfEvtMouseMoved: $(unsafe_load(event_ptr.mouseMove).x), $(unsafe_load(event_ptr.mouseMove).y)")
        end
        event_ref.x.type == sfEvtClosed && sfRenderWindow_close(window)
        handleKeys(event_ref.x)
        mouseHandler(event_ref.x)
    end

    sfText_setString(text, string("FPS:", floor(fps)))
    sfText_setString(selectedBlockText, string("block:", selectedBlock))

    # clear the screen
    sfRenderWindow_clear(window, sfColor_fromRGBA(0, 0, 0, 1))



    # draw the sprite
    # newBoardSprite = updateBoard()

    # make pysics happen

    if (currentTime - lastPhysicsTick > 0.01)
        global lastPhysicsTick = currentTime
        physicsTick(board)
    end

    #draw board
    updateImageBuffer()
    texture = sfTexture_createFromImage(imageBuffer, C_NULL)
    @assert texture != C_NULL

    sfSprite_setTexture(sprite, texture, sfTrue)
    sfRenderWindow_drawSprite(window, sprite, C_NULL)


    sfRenderWindow_drawText(window, text, C_NULL)
    # update the window
    sfRenderWindow_display(window)

end


sfRenderWindow_destroy(window)