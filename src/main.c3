module game_of_life;
import raylib5::rl;
import std::io;
import std::collections::linkedlist;
import std::math::random;

const int[<2>] SCREEN_SIZE = {1400, 950};
const int[<2>] GRID_SIZE = {SCREEN_SIZE.x / CELL_SIZE, SCREEN_SIZE.y / CELL_SIZE};
const int CELL_SIZE = 1;

const int[<2>][*] NBOR_OFFSETS = {{1, 1}, {0, 1}, {-1, 1}, {1, 0}, {-1, 0}, {1, -1}, {0, -1}, {-1, -1}};

alias World = bool[GRID_SIZE.x][GRID_SIZE.y];

World[2] buffers;
World* front = &buffers[0];
World* back = &buffers[1];

LinkedList {uint[<2>]} event_queue;

fn int main(String[] args)
{
	foreach (&row : back) foreach (&cell : row) *cell = rnd() > 0.5;
	(*back)[0][1] = true;
	(*back)[1][2] = true;
	(*back)[2][0..2] = true;
	rl::initWindow(...SCREEN_SIZE, "Game of life on CPU");
	defer rl::closeWindow();
	rl::setTargetFPS(60);

	while (!rl::windowShouldClose())
	{
		rl::@drawing()
		{
			rl::clearBackground(rl::BLACK);
			usz count;
			foreach (int y, &row : back)
			{
				foreach (int x, cell : row)
				{
					char n = count_nbors(x, y);
					if (cell)
					{
						count ++;
						(*front)[y][x] = n == 3 || n == 2;
					}
					else
					{
						(*front)[y][x] = n == 3;
					}
					// rl::drawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE, cell ? rl::WHITE : rl::BLACK);
					if (cell) rl::drawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE, rl::WHITE);
				}
			}
			// foreach (int y, row : front) foreach (int x, cell : row) rl::drawRectangle(x, y, 1, 1, cell == true ? rl::WHITE : rl::BLACK);
			rl::drawFPS(20, 20);
			@pool()
			{
				rl::drawText(string::tformat_zstr("%s alive cells", count), 20, 50, 20, rl::LIGHTGRAY);
			};
		};
		@swap(front, back);
	}
	return 0;
}

macro mod(a, b)
{
	switch
	{
		case a == 0: return 0;
		case (a > 0) == (b > 0): return a % b;
		default: return (a % b) + b;
	}
}

fn char count_nbors(int x, int y)
{
	char c;
	foreach (off : NBOR_OFFSETS)
	{
		if ((*back)[mod(y + off.y, GRID_SIZE.y)][mod(x + off.x, GRID_SIZE.x)]) c++;
	}
	return c;
}
