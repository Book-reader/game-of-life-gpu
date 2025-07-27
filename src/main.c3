module game_of_life;
import std::io;
import std::math::random;

import raylib5::rl;

// See if I can do something with this:
// typedef Neighbours = Cell[<8>];


enum Cell : const char
{
	DEAD = 0,
	ALIVE = 255,
}

const WIDTH = 800;
const HEIGHT = 600;
// const WIDTH = 20;
// const HEIGHT = 20;
typedef World = Cell[HEIGHT][WIDTH];

macro mod(dividend, divisor)
{
	switch
	{
		case dividend == 0: return 0;
		case dividend > 0: return dividend % divisor;
		default: return (dividend % divisor) + divisor;
	}
}

World world;
World prev;
fn char World.count_neighbours(&self, usz cell_x, usz cell_y)
{
	char count;
	for (isz x = cell_x - 1; x < cell_x + 2; x ++)
	{
		for (isz y = cell_y - 1; y < cell_y + 2; y ++)
		{
			// io::print((*self)[mod(x, WIDTH)][mod(y, HEIGHT)] == ALIVE ? "1" : "0");
			// io::printfn("x: %s, y: %s, mod(x): %s, mod(y): %s", x, y, mod(x, WIDTH), mod(y, HEIGHT));
			if (x != cell_x || y != cell_y) count += (char)((*self)[mod(x, WIDTH)][mod(y, HEIGHT)] == ALIVE);
		}
		// io::printn();
	}
	return count;
}

fn int main(String[] args)
{
	foreach (&row : world) foreach (&cell : row) *cell = rnd() > 0.5 ? ALIVE : DEAD;
	world[0][1] = ALIVE;
	world[1][2] = ALIVE;
	world[2][0..2] = ALIVE;
	//world[]
	// io::printn("Hello, World!");
	rl::initWindow(WIDTH, HEIGHT, "Game of Life");
	defer rl::closeWindow();

	Image world_img = {
		.data = &world,
		.width = WIDTH,
		.height = HEIGHT,
		.format = UNCOMPRESSED_GRAYSCALE,
		.mipmaps = 1,
	};
	Texture2D world_tex = rl::loadTextureFromImage(world_img);
	// rl::setTargetFPS(60);

	while (!rl::windowShouldClose()) rl::@drawing()
	{
		prev = world;
		rl::clearBackground(rl::WHITE);
		rl::updateTexture(world_tex, &world);
		rl::drawTexture(world_tex, 0, 0, rl::WHITE);

		usz alive;
		for (int x = 0; x < WIDTH; x++) for (int y = 0; y < HEIGHT; y++)
		{
			char n = prev.count_neighbours(x, y);
			// if (n != 0 && (n > 3 || n < 2)) io::printn(n);
			if (prev[x][y] == ALIVE)
			{
				alive ++;
				// world[x][y] = n == 3 || n == 2 ? ALIVE : DEAD;
				switch (n)
				{
					case 0..1:
					case 4..8:
						// io::printfn("killing cell at %s:%s", x, y);
						world[x][y] = DEAD;
					case 2..3:
						// world[x][y] = ALIVE;
						break;
					default:
						unreachable("cannot have more than 8 neighbours");
				}
			}
			else if (n == 3)
			{
				// io::printfn("reviving dead cell at %s:%s", x, y);
				world[x][y] = ALIVE;
			}
		}
		
		// static usz frames;
		// io::printfn("end of frame %s", ++frames);
		rl::drawFPS(20, 20);
		@pool() { rl::drawText(string::tformat_zstr("Alive cells: %s", alive), 20, 50, 32, rl::GREEN); };
	};

	
	return 0;
}
