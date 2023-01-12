using CSFML
using CSFML.LibCSFML

include("Voxel.jl")
using .Voxel: newVoxel

# enums of particle types, sand, stone, water, etc
const AIR = 0
const STONE = 1
const SAND = 2
# const WATER = 3

windowWidth = 640
windowHeight = 480
leftPressed = false

# TODO figure out how I want to handle resizing and map size in general

board = [[newVoxel(AIR) for i in 0:windowWidth-1] for j in 0:windowHeight-1]

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

function updateClickedPixel()
    mousePos = sfMouse_getPositionRenderWindow(window)
    if mousePos.x < 0 || mousePos.x >= windowWidth || mousePos.y < 0 || mousePos.y >= windowHeight
        return
    end

    # set boards voxel to new color
    board[mousePos.y+1][mousePos.x+1] = newVoxel(SAND)

end

function mouseHandler(event::sfEvent)
    isLeft = sfMouseLeft == event.mouseButton.button
    # rightPress = sfMouseRight == event.mouseButton.button
    if event.type == sfEvtMouseButtonPressed && isLeft
        updateClickedPixel()
        global leftPressed = true
    end

    if event.type == sfEvtMouseMoved && leftPressed
        updateClickedPixel()
    end

    if event.type == sfEvtMouseButtonReleased && isLeft
        global leftPressed = false
    end
end

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
        mouseHandler(event_ref.x)
    end

    sfText_setString(text, string("FPS:", floor(fps)))

    # clear the screen
    sfRenderWindow_clear(window, sfColor_fromRGBA(0, 0, 0, 1))



    # draw the sprite
    # newBoardSprite = updateBoard()

    #update board
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