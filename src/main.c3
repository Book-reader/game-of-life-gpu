module game_of_life;
import raylib5::rl;
import std::io;
import std::collections::linkedlist;
import std::collections::list;
import std::collections::set;
import std::collections::map;
import std::math::random;

const int[<2>] SCREEN_SIZE = {1400, 950};
const int[<2>] GRID_SIZE = {SCREEN_SIZE.x / CELL_SIZE, SCREEN_SIZE.y / CELL_SIZE};
const int CELL_SIZE = 2;

const int[<2>][*] NBOR_OFFSETS = {
	{-1, -1}, {0, -1}, {1, -1},
	{-1, 0},           {1, 0},
	{-1, 1}, {0, 1}, {1, 1},
};

const int[<2>][*] OFFSETS = {
	{-1, -1}, {0, -1}, {1, -1},
	{-1, 0}, {0, 0}, {1, 0},
	{-1, 1}, {0, 1}, {1, 1},
};


/*struct Cell //@packed
{
	bool alive;
	char neighbours;
}*/
bitstruct Cell : char
{
	bool alive;
	bool notified;
}

typedef World = Cell[GRID_SIZE.x][GRID_SIZE.y];
macro bool World.@get(#world, x, y) => #world[y][x];
macro void World.@set(#world, x, y, bool val)
{
	event_queue.push({{x, y}, val});
}

macro Cell World.get(&self, int[<2>] pos) => (*self)[pos.y][pos.x];
macro void World.set(&self, int[<2>] pos, Cell val) => (*self)[pos.y][pos.x] = val;

World[2] buffers;
World* front = &buffers[0];
World* back = &buffers[1];

// World world;
struct Event//  @packed
{
	int[2] pos;
	EventType type;
	// bool alive;
}

enum EventType : char
{
	CREATE,
	DIE,
	REVIVE,
	_UPDATE,
	_CHANGED,
}
LinkedList {int[2]} event_queue;
// LinkedList {int[2]} next_queue;

HashMap {int, HashMap {int, bool}} a;

macro emit_event(int[<2>] pos) => event_queue.push(pos);

fn int main(String[] args)
{
	event_queue.init(mem);
	defer event_queue.free();

	foreach (uint y, &row : back) foreach (uint x, cell : row)
	{
		if (rnd() > 0.5)
		{
			(*back)[y][x].alive = true;
			emit_event({x, y});
		}
	}
	emit_event({1, 0});
	emit_event({2, 1});
	emit_event({0, 2});
	emit_event({1, 2});
	emit_event({2, 2});
	(*back)[0][1].alive = true;
	(*back)[1][2].alive = true;
	(*back)[2][0].alive = true;
	(*back)[2][1].alive = true;
	(*back)[2][2].alive = true;

	rl::initWindow(...SCREEN_SIZE, "Game of life on CPU");
	defer rl::closeWindow();
//	rl::setTargetFPS(60);

	while (!rl::windowShouldClose()) rl::@drawing()
	{
		// rl::clearBackground(rl::BLACK);
		usz alive;
		usz events = event_queue.len();
		io::printfn("got %s events", events);
		while (events-- > 0)
		{
			int[<2>] pos = event_queue.pop_front()!!;

			// rl::drawRectangle(pos.x * CELL_SIZE, pos.y * CELL_SIZE, CELL_SIZE, CELL_SIZE, front.get(pos).alive ? rl::WHITE : rl::BLACK);
			// rl::drawRectangle(...pos * CELL_SIZE, CELL_SIZE, CELL_SIZE, back.get(pos).alive ? rl::WHITE : rl::BLACK);
			foreach (off : OFFSETS)
			{
				int[<2>] pos1 = mod2(pos + off, GRID_SIZE);
				char n = count_nbors(back, pos1);
				// notified.add(pos1);

				(*back)[pos1.y][pos1.x].notified = false;

				if (back.get(pos1).alive)
				{
					(*front)[pos1.y][pos1.x].alive = n == 2 || n == 3;
				}
				else
				{
					(*front)[pos1.y][pos1.x].alive = n == 3;
				}
				if (front.get(pos1).alive != back.get(pos1).alive && front.get(pos1).notified == false)
				{
					(*front)[pos1.y][pos1.x].notified = true;
					emit_event(pos1);
				}
				// if (off == {0, 0}) rl::drawRectangle(...pos1 * CELL_SIZE, CELL_SIZE, CELL_SIZE, front.get(pos1).alive ? rl::WHITE : rl::BLACK);
			}
		}
/*		foreach (int y, &row : back) foreach (int x, cell : row)
		{
			char n = count_nbors(back, {x, y});
			if ((*back)[y][x].alive)
			{
				(*front)[y][x].alive = n == 3 || n == 2;
			}
			else
			{
				(*front)[y][x].alive = n == 3;
			}
		}*/

		foreach (int y, &row : back) foreach (int x, cell : row)
		{
			alive += (usz)cell.alive;
			rl::drawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE, cell.alive ? rl::WHITE : rl::BLACK);
		}
		// for (int x = 0; x < GRID_SIZE.x; x++) for (int y = 0; y < GRID_SIZE.y; y++) rl::drawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE, back.get({x,y}).alive ? rl::WHITE : rl::BLACK);
		rl::drawFPS(20, 20);
		@pool()
		{
			rl::drawText(string::tformat_zstr("%s alive cells", alive), 20, 50, 20, rl::LIGHTGRAY);
		};
		@swap(front, back);
	};
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

macro mod2(a, b) => ($typeof(a)){mod(a.x, b.x), mod(a.y, b.y)};

fn char count_nbors(World* world, int[<2>] pos)
{
	char c;
	foreach (off : NBOR_OFFSETS)
	{
		if ((*world)[mod(pos.y + off.y, GRID_SIZE.y)][mod(pos.x + off.x, GRID_SIZE.x)]) c++;
	}
	return c;
}
