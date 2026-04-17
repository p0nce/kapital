import turtle;
import brutor;

int main(string[] args)
{
    runGame(new BrutorGame);
    return 0;
}

class BrutorGame : TurtleGame
{
    GameState state;

    override void load()
    {
        setBackgroundColor(color("#1a1a2e"));
        setTitle("Brutor");
        console.size(60, 30);

        state.reset();
        state.startTurn();
        state.doRoll();
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape")) exitGame;
    }

    override void mousePressed(float x, float y, MouseButton button, int repeat)
    {
        if (button == MouseButton.left)
        {
            state.handleClick(x, y, windowWidth);
        }
    }

    override void draw()
    {
        console.cls();
        state.draw(canvas, console, windowWidth, windowHeight);
    }
}
