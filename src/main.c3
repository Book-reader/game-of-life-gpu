module game_of_life;
import std::io;
import std::math::random;

import load;

import raylib5::rl;

enum Cell : const char
{
	DEAD = 0,
	ALIVE = 255,
}

const SCREEN_WIDTH = 1920;
const SCREEN_HEIGHT = 1080;
const float SCALE = 1.0; // 0.12; // 0.1178; // 0.125;
const WIDTH = (usz)(SCREEN_WIDTH / SCALE);
const HEIGHT = (usz)(SCREEN_HEIGHT / SCALE);


typedef World = Cell[WIDTH * 4][HEIGHT];

macro mod(dividend, divisor)
{
	switch
	{
		case dividend == 0: return 0;
		case dividend > 0: return dividend % divisor;
		default: return (dividend % divisor) + divisor;
	}
}

extern fn void rlSetBlendFactorsSeparate(int glSrcRGB, int glDstRGB, int glSrcAlpha, int glDstAlpha, int glEqRGB, int glEqAlpha);

World world;

fn int main(String[] args)
{
	/*if (args.len == 2) @pool()
	{
		String file = (String)file::load(tmem, args[1])!!;
		foreach (y, ln: *(Cell[][]*)&&load::decode(tmem, file))
		{
			world[y][:ln.len] = ln[..];
		}
	};
	if (args.len != 2) foreach (&row : world) /*foreach (&cell : row) *cell*/for (usz i = 0; i < WIDTH * 4; i++) (*row)[i] = rnd() > 0.5 ? ALIVE : DEAD;*/
	world[0][1] = ALIVE;
	world[1][2] = ALIVE;
	world[2][0..2] = ALIVE;

	rl::initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Game of Life");
	defer rl::closeWindow();

	$assert WIDTH % 4 == 0;
	Image world_img = {
		.data = &world,
		.width = WIDTH/* / 4*/,
		.height = HEIGHT,
		.format = UNCOMPRESSED_R8G8B8A8,
		.mipmaps = 1,
	};
	Texture2D world_tex = rl::loadTextureFromImage(world_img);
	defer rl::unloadTexture(world_tex);

	RenderTexture2D front_tex = rl::loadRenderTexture(WIDTH, HEIGHT);
	defer rl::unloadRenderTexture(front_tex);

	RenderTexture2D back_tex = rl::loadRenderTexture(WIDTH, HEIGHT);
	defer rl::unloadRenderTexture(back_tex);

	// Initial copy of randomised world texture onto the front buffer
	rl::@textureMode(front_tex)
	{
		rl::@blendMode(3)
		{
			rl::drawTexture(world_tex, 0, 0, rl::WHITE);
		};
	};

	rl::setTargetFPS(60);

	// rlSetBlendFactorsSeparate(0, 0x0300, 0, 0x0302, 1, 1);

	Shader render_shader = rl::loadShaderFromMemory(vs: null, fs: RENDER_SHADER);
	defer rl::unloadShader(render_shader);

	Shader scaling_shader = rl::loadShaderFromMemory(vs: null, fs: SCALING_SHADER);
	defer rl::unloadShader(scaling_shader);

	float magnification = 1.0;
	float[<2>] camera_pos = {0, 0};
	int mag_loc = rl::getShaderLocation(scaling_shader, "magnification");
	int cpos_loc = rl::getShaderLocation(scaling_shader, "camera_pos");
	while (!rl::windowShouldClose()) rl::@drawing()
	{
		rl::@textureMode(back_tex)
		{
			rl::clearBackground(rl::BLANK);
			rl::@shaderMode(render_shader)
			{
				rl::@blendMode(3) // 7 = RL_BLEND_CUSTOM_SEPARATE. not in raylib55.c3l so I should fix that
				{
					rl::drawTexture(front_tex.texture, 0, 0, rl::WHITE);
				};
			};
		};

		/*{
			Image img = rl::loadImageFromTexture(back_tex.texture);
			defer rl::unloadImage(img);
			foreach (val : ((char[<4>]*)img.data)[:WIDTH * HEIGHT][:10]) io::printfn("%s", val);
			// return 0;
		}*/


		rl::@textureMode(front_tex)
		{
			rl::clearBackground(rl::BLANK);

			rl::@blendMode(3) // 7 = RL_BLEND_CUSTOM_SEPARATE. not in raylib55.c3l so I should fix that
			{
				rl::drawTexture(back_tex.texture, 0, 0, rl::WHITE);
			};
		};

/*		{
			Image img = rl::loadImageFromTexture(front_tex.texture);
			defer rl::unloadImage(img);
			foreach (val : ((char[<4>]*)img.data)[:WIDTH * HEIGHT][:10]) io::printfn("%s", val);
			// return 0;
		}*/


		rl::clearBackground(rl::BLANK);
		rl::setShaderValue(scaling_shader, mag_loc, &magnification, FLOAT);
		rl::setShaderValue(scaling_shader, cpos_loc, &camera_pos, VEC2);
		rl::@shaderMode(scaling_shader)
		{
			// rl::@blendMode(3)
			{
				rl::drawTextureEx(front_tex.texture, {0, 0}, 0.0, SCALE, rl::WHITE);
			};
		};

		const ZOOM_STEP = 0.95;
		const MOVE_STEP = 0.05;
		if (rl::isKeyDown(rl::KEY_PAGE_UP))
		{
			magnification /= ZOOM_STEP;
		}
		if (rl::isKeyDown(rl::KEY_PAGE_DOWN))
		{
			magnification *= ZOOM_STEP;
		}

		if (rl::isKeyDown(rl::KEY_UP))
		{
			camera_pos.y -= MOVE_STEP / magnification;
		}
		if (rl::isKeyDown(rl::KEY_DOWN))
		{
			camera_pos.y += MOVE_STEP / magnification;
		}
		if (rl::isKeyDown(rl::KEY_LEFT))
		{
			camera_pos.x -= MOVE_STEP / magnification;
		}
		if (rl::isKeyDown(rl::KEY_RIGHT))
		{
			camera_pos.x += MOVE_STEP / magnification;
		}
		magnification = magnification.clamp(1, 50 / SCALE);
		camera_pos = camera_pos.clamp({0, 0}, {1 - 1 / magnification, 1 - 1 / magnification});


		//rl::drawRectangle(0, 0, 400, 120, rl::RAYWHITE);
		static usz alive;
		static usz i;
		i++;
		if (i == 100)
		{
			alive = 0; i = 0;
			world_img = rl::loadImageFromTexture(front_tex.texture);
			defer rl::unloadImage(world_img);
			foreach (val : ((char*)world_img.data)[:WIDTH * 4 * HEIGHT]) if (val == 255) alive ++;
		}

		rl::drawFPS(20, 20);
		@pool()
		{
			rl::drawText(string::tformat_zstr("(%s%%) Alive cells: %s/%s", i, alive, WIDTH * HEIGHT), 20, 50, 32, rl::GREEN);
			rl::drawText(string::tformat_zstr("camera pos: %s. magnification: %s", camera_pos, magnification), 20, 80, 15, rl::GREEN);
		};
		rl::drawText(@sprintf("Grid size: %sx%s", WIDTH, HEIGHT), 20, 100, 20, rl::GREEN);
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
//	for (int i = 0; i <= 4; i++)

	vec4 left = getPixelAtOffset(-1.0, 0.0);
	vec4 right = getPixelAtOffset(1.0, 0.0);

	vec4 above = getPixelAtOffset(0.0, -1.0);
	vec4 above_left = getPixelAtOffset(-1.0, -1.0);
	vec4 above_right = getPixelAtOffset(1.0, -1.0);

	vec4 below = getPixelAtOffset(0.0, 1.0);
	vec4 below_left = getPixelAtOffset(-1.0, 1.0);
	vec4 below_right = getPixelAtOffset(1.0, 1.0);

	// TODO: unroll manually if it significantly impacts performance
	for (int i = 0; i < 4; i++)
	{
		// First, the R channel
		int count = 0;
		count += i == 0 ? int(left[3] == 1.0) : int(texelColor[i - 1] == 1.0);
		count += i == 0 ? int(above_left[3] == 1.0) : int(above[i - 1] == 1.0);
		count += i == 0 ? int(below_left[3] == 1.0) : int(below[i - 1] == 1.0);
		count += i == 3 ? int(right[0] == 1.0) : int(texelColor[i + 1] == 1.0);
		count += i == 3 ? int(above_right[0] == 1.0) : int(above[i + 1] == 1.0);
		count += i == 3 ? int(below_right[0] == 1.0) : int(below[i + 1] == 1.0);
		count += int(above[i] == 1.0);
		count += int(below[i] == 1.0);


		if (texelColor[i] == 0.0)
		{
			finalColor[i] = float(count == 3);// ? 1.0, 0.0, 0.0, 0.0) : vec4(0.0, 0.0, 0.0, 0.0);
		}
		else
		{
			finalColor[i] = float(count == 3 || count == 2); // ? vec4(1.0, 0.0, 0.0, 0.0) : vec4(0.0, 0.0, 0.0, 0.0);
		}
	}

	// finalColor.gba = vec3(0.0);
}
`, WIDTH, HEIGHT);

/*const SCALING_SHADER =
`
#version 330
in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

out vec4 finalColor;

void main()
{
	finalColor = vec4(fragTexCoord, 0.0, 1.0);
}
`;*/


const SCALING_SHADER =
`
#version 330
in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

out vec4 finalColor;

uniform float magnification = 1.0;
uniform vec2 camera_pos = vec2(0.0, 0.0);

vec4 getCoords()
{
	// this inverts the Y coordinate to unflip the image to the correct orientation
	return texture(texture0, (vec2(fragTexCoord.x, -fragTexCoord.y) / magnification) + vec2(camera_pos.x, -camera_pos.y));
}

void main()
{
	vec4 texelColor = getCoords()*colDiffuse*fragColor;
	finalColor = vec4(texelColor.rgb, texelColor.a + 0.5);
}
`;

