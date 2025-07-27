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

/*enum Cell : const bool
{
	DEAD = false,
	ALIVE = true,
}*/

// const WIDTH = 800;
// const HEIGHT = 600;
// const WIDTH = 20;
// const HEIGHT = 20;
// const WIDTH = 1280; //1920;
// const HEIGHT = 720; //1080;
const SCREEN_WIDTH = 1920;
const SCREEN_HEIGHT = 1080;
const float SCALE = 1.0;
const WIDTH = (usz)(SCREEN_WIDTH / SCALE);
const HEIGHT = (usz)(SCREEN_HEIGHT / SCALE);

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

World[2] bufs;
World* world = &bufs[0];
World* prev = &bufs[1];
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

fn bool[8] World.get_neighbours(&self, usz cell_x, usz cell_y)
{
	bool[8] list;
	usz idx;
	for (int x_off = -1; x_off < 2; x_off ++)
	{
		for (int y_off = -1; y_off < 2; y_off ++)
		{
			if (x_off != 0 || y_off != 0) list[idx++] = (*self)[mod(cell_y + y_off, HEIGHT)][mod(cell_x + x_off, WIDTH)] == ALIVE;
		}
	}
	return list;

}

fn int main(String[] args)
{
	foreach (&row : world) foreach (&cell : row) *cell = rnd() > 0.5 ? ALIVE : DEAD;
	(*world)[0][1] = ALIVE;
	(*world)[1][2] = ALIVE;
	(*world)[2][0..2] = ALIVE;
	//world[]
	// io::printn("Hello, World!");
	rl::initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Game of Life");
	defer rl::closeWindow();

	Image world_img = {
		.data = world,
		.width = WIDTH,
		.height = HEIGHT,
		.format = UNCOMPRESSED_GRAYSCALE,
		.mipmaps = 1,
	};
	Texture2D world_tex = rl::loadTextureFromImage(world_img);
	defer rl::unloadTexture(world_tex);
	RenderTexture2D res_tex = rl::loadRenderTexture(WIDTH, HEIGHT);
	defer rl::unloadRenderTexture(res_tex);
	// rl::setTargetFPS(10);

	Shader boolean_transparency = rl::loadShaderFromMemory(vs: null, fs: SHADER);
	defer rl::unloadShader(boolean_transparency);

	float magnification = 1.0;
	int mag_loc = rl::getShaderLocation(boolean_transparency, "magnification");
	int nbor_loc = rl::getShaderLocation(boolean_transparency, "neighbours");
	while (!rl::windowShouldClose()) rl::@drawing()
	{
		// rl::setShaderValue(boolean_transparency, mag_loc, &magnification, FLOAT);

		// @swap(world, prev);
		// rl::clearBackground(rl::WHITE);
		// rl::updateTexture(world_tex, world);

		rl::@textureMode(res_tex)
		{
			rl::clearBackground(rl::WHITE);
		// TODO: the scaling has to be done seperately
			rl::@shaderMode(boolean_transparency)
			{
				// rl::drawTextureRec(world_tex, {0, 0, WIDTH, -HEIGHT}, {0, 0}, rl::WHITE);
				rl::drawTexture(world_tex, 0, 0, rl::WHITE);
			};
		};
		// rl::drawTextureEx(res_tex.texture, {0, 0}, 0.0, SCALE, rl::WHITE);
		rl::drawTexturePro(res_tex.texture, {0, 0, WIDTH, HEIGHT}, {0, 0, SCREEN_WIDTH, SCREEN_HEIGHT}, {0, 0}, 0.0, rl::WHITE);

		// rl::unloadImage(world_img);
		world_img = rl::loadImageFromTexture(res_tex.texture);
		rl::imageFlipVertical(&world_img);
		world_tex = rl::loadTextureFromImage(world_img);

		usz alive;
/*		for (usz x = 0; x < WIDTH; x++) for (usz y = 0; y < HEIGHT; y++)
		{
			
			char n = prev.count_neighbours(x, y);
			// if (n != 0 && (n > 3 || n < 2)) io::printn(n);
			if ((*prev)[y][x] == ALIVE)
			{
				alive ++;
				(*world)[y][x] = n == 3 || n == 2 ? ALIVE : DEAD;
/*				switch (n)
				{
					case 0..1:
					case 4..8:
						// io::printfn("killing cell at %s:%s", x, y);
						(*world)[y][x] = DEAD;
					case 2..3:
						(*world)[y][x] = ALIVE;
						break;
					default:
						unreachable("cannot have more than 8 neighbours");
				}*/
			}
			else
			{
				(*world)[y][x] = (n == 3) ? ALIVE : DEAD;
			}
		}*/
		// magnification += 0.01;
		// static usz frames;
		// io::printfn("end of frame %s", ++frames);
		foreach (val : ((char[<4>]*)world_img.data)[:world_img.width * world_img.height])
		{
			if (val.r == 255) alive ++;
		}
		rl::drawFPS(20, 20);
		@pool() { rl::drawText(string::tformat_zstr("Alive cells: %s", alive), 20, 50, 32, rl::GREEN); };
		rl::drawText(@sprintf("Grid size: %sx%s", WIDTH, HEIGHT), 20, 80, 20, rl::GREEN);
	};

	
	return 0;
}

const SHADER = @sprintf(
`
#version 330
in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

#define WIDTH %s
#define HEIGHT %s

out vec4 finalColor;

uniform float magnification = 1.0;
// uniform bool neighbours[8];

vec4 getCoords()
{
	return texture(texture0, fragTexCoord / magnification);
}

vec4 getPixelAtOffset(float x, float y)
{
	return texture(texture0, (fragTexCoord + vec2(x / WIDTH, y / HEIGHT)) / magnification);
}

#define DEAD vec4(0.0, 0.0, 0.0, 1.0)
#define ALIVE vec4(1.0, 1.0, 1.0, 1.0)

void main()
{
	vec4 texelColor = getCoords()*colDiffuse*fragColor;

	int count = 0;
	count += int(getPixelAtOffset(-1.0, -1) == ALIVE);
	count += int(getPixelAtOffset(-1.0, 0.0) == ALIVE);
	count += int(getPixelAtOffset(-1.0, 1.0) == ALIVE);

	count += int(getPixelAtOffset(0.0, -1.0) == ALIVE);
	count += int(getPixelAtOffset(0.0, 1.0) == ALIVE);

	count += int(getPixelAtOffset(1.0, -1.0) == ALIVE);
	count += int(getPixelAtOffset(1.0, 0.0) == ALIVE);
	count += int(getPixelAtOffset(1.0, 1.0) == ALIVE);

	// finalColor = texelColor == DEAD ? count == 3 ? ALIVE : DEAD : count == 2 || count == 3 ? ALIVE : DEAD;
/*	if (fragTexCoord.x < 0.1 && fragTexCoord.y < 0.1)
	{
		finalColor = vec4(1.0, 0.0, 0.0, 1.0);
	}
	else*/ if (texelColor == DEAD)
	{
		finalColor = count == 3 ? ALIVE : DEAD;
	}
	else
	{
		finalColor = count == 3 || count == 2 ? ALIVE : DEAD;
	}
}
`, WIDTH, HEIGHT);
