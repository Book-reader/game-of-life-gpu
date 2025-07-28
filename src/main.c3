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

	RenderTexture2D front_tex = rl::loadRenderTexture(WIDTH, HEIGHT);
	defer rl::unloadRenderTexture(front_tex);

	RenderTexture2D back_tex = rl::loadRenderTexture(WIDTH, HEIGHT);
	defer rl::unloadRenderTexture(back_tex);

	rl::@textureMode(front_tex)
	{
		rl::drawTexture(world_tex, 0, 0, rl::WHITE);
	};

	// rl::setTargetFPS(10);

	Shader render_shader = rl::loadShaderFromMemory(vs: null, fs: RENDER_SHADER);
	defer rl::unloadShader(render_shader);

	Shader scaling_shader = rl::loadShaderFromMemory(vs: null, fs: SCALING_SHADER);
	defer rl::unloadShader(scaling_shader);

	float magnification = 1.0;
	int mag_loc = rl::getShaderLocation(scaling_shader, "magnification");
	// int nbor_loc = rl::getShaderLocation(render_shader, "neighbours");
	while (!rl::windowShouldClose()) rl::@drawing()
	{
		// @swap(world, prev);
		// rl::clearBackground(rl::WHITE);
		// rl::updateTexture(world_tex, world);

		rl::@textureMode(back_tex)
		{
			rl::clearBackground(rl::WHITE);
			// TODO: the scaling has to be done seperately
			rl::@shaderMode(render_shader)
			{
				rl::drawTextureRec(front_tex.texture, {0, 0, WIDTH, HEIGHT}, {0, 0}, rl::WHITE);
				// rl::drawTexture(front_tex.texture, 0, 0, rl::WHITE);
			};
		};
		// rl::drawTextureEx(res_tex.texture, {0, 0}, 0.0, SCALE, rl::WHITE);
		// rl::drawTexturePro(back_tex.texture, {0, 0, WIDTH, HEIGHT}, {0, 0, SCREEN_WIDTH, SCREEN_HEIGHT}, {0, 0}, 0.0, rl::WHITE);

		rl::@textureMode(front_tex)
		{
			rl::drawTexture(back_tex.texture, 0, 0, rl::WHITE);
		};

		rl::setShaderValue(scaling_shader, mag_loc, &magnification, FLOAT);
		rl::@shaderMode(scaling_shader)
		{
			// rl::drawTexturePro(front_tex.texture, {0, 0, WIDTH, -HEIGHT}, {500, 500, WIDTH, HEIGHT}, {0, 0}, 0.0, rl::WHITE);
			rl::drawTextureEx(front_tex.texture, {0, 0}, 0.0, SCALE, rl::WHITE);
		};

		const STEP = 0.95;
		if (rl::isKeyDown(rl::KEY_PAGE_UP) && magnification < 10)
		{
			magnification /= STEP;
		}
		if (rl::isKeyDown(rl::KEY_PAGE_DOWN) && magnification > 1)
		{
			magnification *= STEP;
		}
		// if (rl::isKeyDown)


		rl::drawRectangle(0, 0, 350, 120, rl::RAYWHITE);
		usz alive;
		world_img = rl::loadImageFromTexture(front_tex.texture);
		defer rl::unloadImage(world_img);
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

const RENDER_SHADER = @sprintf(
`
#version 330
in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

#define WIDTH %s
#define HEIGHT %s

out vec4 finalColor;

vec4 getCoords()
{
	return texture(texture0, fragTexCoord);
}

vec4 getPixelAtOffset(float x, float y)
{
	return texture(texture0, (fragTexCoord + vec2(x / WIDTH, y / HEIGHT)));
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

	if (texelColor == DEAD)
	{
		finalColor = count == 3 ? ALIVE : DEAD;
	}
	else
	{
		finalColor = count == 3 || count == 2 ? ALIVE : DEAD;
	}
}
`, WIDTH, HEIGHT);

const SCALING_SHADER =
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
	// this inverts the Y coordinate to unflip the image to the correct orientation
	return texture(texture0, vec2(fragTexCoord.x, -fragTexCoord.y) / magnification);
}

void main()
{
	vec4 texelColor = getCoords()*colDiffuse*fragColor;
	finalColor = texelColor;
}
`;
