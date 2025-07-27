module game_of_life;
import std::io;
import std::math::random;

import raylib5::rl;

// See if I can do something with this:
// typedef Neighbours = Cell[<8>];


/*enum Cell : const char
{
	DEAD = 0,
	ALIVE = 255,
}*/

enum Cell : const bool
{
	DEAD = false,
	ALIVE = true,
}

// const WIDTH = 800;
// const HEIGHT = 600;
// const WIDTH = 20;
// const HEIGHT = 20;
const WIDTH = 1920;
const HEIGHT = 1080;
typedef World = Cell[WIDTH][HEIGHT];

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
	/*for (isz x = cell_x - 1; x < cell_x + 2; x ++)
	{
		for (isz y = cell_y - 1; y < cell_y + 2; y ++)
		{
			// io::print((*self)[mod(x, WIDTH)][mod(y, HEIGHT)] == ALIVE ? "1" : "0");
			// io::printfn("x: %s, y: %s, mod(x): %s, mod(y): %s", x, y, mod(x, WIDTH), mod(y, HEIGHT));
			if (x != cell_x || y != cell_y) count += (char)((*self)[mod(y, HEIGHT)][mod(x, WIDTH)] == ALIVE);
		}
		// io::printn();
	}*/
	for (int x_off = -1; x_off < 2; x_off ++)
	{
		for (int y_off = -1; y_off < 2; y_off ++)
		{
			if (x_off != 0 || y_off != 0) count += (char)((*self)[mod(cell_y + y_off, HEIGHT)][mod(cell_x + x_off, WIDTH)] == ALIVE);
		}
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

	Shader boolean_transparency = rl::loadShaderFromMemory(vs: null, fs: SHADER);
	defer rl::unloadShader(boolean_transparency);

	float magnification = 1.0;
	int mag_loc = rl::getShaderLocation(boolean_transparency, "magnification");
	while (!rl::windowShouldClose()) rl::@drawing()
	{
		rl::setShaderValue(boolean_transparency, mag_loc, &magnification, FLOAT);
		prev = world;
		rl::clearBackground(rl::WHITE);
		rl::updateTexture(world_tex, &world);

		rl::beginShaderMode(boolean_transparency);
			rl::drawTexture(world_tex, 0, 0, rl::WHITE);
		rl::endShaderMode();

		usz alive;
		for (usz x = 0; x < WIDTH; x++) for (usz y = 0; y < HEIGHT; y++)
		{
			char n = prev.count_neighbours(x, y);
			// if (n != 0 && (n > 3 || n < 2)) io::printn(n);
			if (prev[y][x] == ALIVE)
			{
				alive ++;
				// world[x][y] = n == 3 || n == 2 ? ALIVE : DEAD;
				switch (n)
				{
					case 0..1:
					case 4..8:
						// io::printfn("killing cell at %s:%s", x, y);
						world[y][x] = DEAD;
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
				world[y][x] = ALIVE;
			}
		}
		magnification += 0.01;
		// static usz frames;
		// io::printfn("end of frame %s", ++frames);
		rl::drawFPS(20, 20);
		@pool() { rl::drawText(string::tformat_zstr("Alive cells: %s", alive), 20, 50, 32, rl::GREEN); };
		rl::drawText(@sprintf("Grid size: %sx%s", WIDTH, HEIGHT), 20, 80, 20, rl::GREEN);
	};

	
	return 0;
}

const SHADER =
`
#version 330
in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

out vec4 finalColor;

uniform float magnification = 1.0;
vec4 getCoords()
{
	return texture(texture0, fragTexCoord / magnification);
}

void main()
{
	vec4 texelColor = getCoords()*colDiffuse*fragColor;

	finalColor = texelColor == vec4(0.0, 0.0, 0.0, 1.0) ? vec4(0.0, 0.0, 0.0, 1.0) : vec4(1.0, 1.0, 1.0, 1.0);
}
`;
