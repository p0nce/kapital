import turtle;

int main(string[] args)
{
    runGame(new BrutorGame);
    return 0;
}

class BrutorGame : TurtleGame
{
    override void load()
    {
        setBackgroundColor(color("#1a1a2e"));
        setTitle("Brutor");
        console.size(60, 30);
    }

    override void update(double dt)
    {
        if (keyboard.isDown("escape")) exitGame;
    }

    override void draw()
    {
        with (console)
        {
            cls();
            locate(20, 14);
            fg(TM_colorWhite);
            print("BRUTOR");
        }
    }
}
