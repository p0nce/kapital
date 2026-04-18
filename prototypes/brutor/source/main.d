import turtle;
import textmode;
import brutor;

int main(string[] args)
{
    runGame(new BrutorGame);
    return 0;
}

class BrutorGame : TurtleGame
{
    GameState state;
    TM_Palette pal = TM_paletteCouture;

    override void load()
    {
        setBackgroundColor(color("#140606"));
        setTitle("Brutor");
        console.size(GameState.CONSOLE_COLS, GameState.CONSOLE_ROWS);
        console.palette(pal);
        // Couture has no real blue — override LBlue so the MP bar pops.
        console.setPaletteEntry(TM_colorLBlue, 70, 130, 220, 255);

        state.reset();
        state.startTurn();
        state.doRoll();
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape")) exitGame;
        state.update(dt);
        console.update(dt); // drives <blink> in text-mode
    }

    override void keyPressed(KeyConstant key)
    {
        if (key == "space" || key == "return")
        {
            state.handleRollKey();
        }
    }

    override void mouseMoved(float x, float y, float dx, float dy)
    {
        state.updateMousePos(x, y, cast(float) windowWidth, cast(float) windowHeight);
    }

    override void mousePressed(float x, float y, MouseButton button, int repeat)
    {
        if (button == MouseButton.left)
        {
            state.handleClick(x, y, cast(float) windowWidth, cast(float) windowHeight);
        }
    }

    override void draw()
    {
        console.cls();
        state.draw(canvas, console, cast(float) windowWidth, cast(float) windowHeight);
    }
}
