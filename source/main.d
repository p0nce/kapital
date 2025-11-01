import std;
import turtle;

int main(string[] args)
{
    runGame(new Kapital);
    return 0;
}

int cameraX = 0;
int cameraY = 0;

// In this incremental game, we must obtain the maximum amount of D-man.
class Kapital : TurtleGame
{
    enum CHAR_WIDTH = 40;
    enum CHAR_HEIGHT = 20;
    enum SEA_LEVEL = CHAR_HEIGHT - 1;
    enum GROUND_LEVEL = CHAR_HEIGHT - 2;

    override void load()
    {
        setBackgroundColor( color("rgb(38,38,54)") );
        setTitle("Incremental");

        console.size(CHAR_WIDTH, CHAR_HEIGHT);
    }

    enum FPS = 24;
    double accum = 0;
    double frameTime = 1.0 / 24.0;

    bool needDraw = true;

    override void update(double dt)
    {
        if (keyboard.isDown("escape")) exitGame;
        accum += dt;
        while (accum >= frameTime)
        {
            accum -= frameTime;
            updateFixed();
        }
    }

    void updateFixed()
    {
        needDraw = true;
        console.update(frameTime);
        if (keyboard.isDown("right"))
        {
            cameraX += 1;
            if (cameraX < 0) cameraX = 0;
        }

        if (keyboard.isDown("left"))
        {
            cameraX -= 1;
            if (cameraX > 50) cameraX = 50;
        }

        if (keyboard.isDown("up"))    pal = ((pal + 1) + TM_paletteNyx+1) % (TM_paletteNyx+1);
        if (keyboard.isDown("down"))  pal = ((pal - 1) + TM_paletteNyx+1) % (TM_paletteNyx+1);
    }

    TM_Palette pal;

    void drawChar(int x, 
                  int y, 
                  dchar ch, 
                  TM_Color fg, 
                  TM_Color bg = TM_colorBlack,
                  TM_Style style = 0
                  )
    {
        int W = CHAR_WIDTH;
        int H = CHAR_HEIGHT;        
        x -= cameraX;
        y -= cameraY;
        if (cast(uint)x >= W) return;
        if (cast(uint)y >= H) return;
        console.charAt(x, y).glyph = ch;

        // PERF: use single charAt
        console.charAt(x, y).color = cast(ubyte)( (bg << 4) + fg );
        console.charAt(x, y).style = style;

    }

    override void draw()
    {
        console.cls;
        ubyte r, g, b, a;

        console.palette(pal);

        console.getPaletteEntry(0, r, g, b, a);
        a = 255;
        console.setPaletteEntry(0, r, g, b, a);

        // Draw floor        
        for (int i = 0; i < 50+CHAR_WIDTH; ++i) 
            drawChar(i, SEA_LEVEL, '█', TM_colorLGrey);

        // Draw someone
        drawChar(20, GROUND_LEVEL-1, 'σ', TM_colorWhite);
        drawChar(20, GROUND_LEVEL, '∏', TM_colorWhite);
    }
}

