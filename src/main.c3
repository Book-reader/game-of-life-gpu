module game_of_life;
import raylib5::rl;
import std::io;
import std::collections::linkedlist;
import std::math::random;

const int[<2>] SCREEN_SIZE = {1400, 950};
const int[<2>] GRID_SIZE = {SCREEN_SIZE.x / CELL_SIZE, SCREEN_SIZE.y / CELL_SIZE};
const int CELL_SIZE = 10;

const int[<2>][*] NBOR_OFFSETS = {{1, 1}, {0, 1}, {-1, 1}, {1, 0}, {-1, 0}, {1, -1}, {0, -1}, {-1, -1}};

struct Cell //@packed
{
	bool alive;
	char neighbours;
}

typedef World = /*Cell*/bool[GRID_SIZE.x][GRID_SIZE.y];
macro bool World.@get(#world, x, y) => #world[y][x];
macro void World.@set(#world, x, y, bool val)
{
	event_queue.push({{x, y}, val});
}

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
}
LinkedList {Event} event_queue;

macro emit_event(int[<2>] pos, EventType type) => event_queue.push({pos, type});

fn int main(String[] args)
{
	event_queue.init(mem);
	defer event_queue.free();

	// foreach (uint y, &row : back) foreach (uint x, cell : row) back.@set(x, y, rnd() > 0.5);
	// back.@set(0, 1, true);
	// back.@set(1, 2, true);
	// back.@set(2, 0, true);
	// back.@set(2, 1, true);
	// back.@set(2, 2, true);
	emit_event({1, 0}, CREATE);
	emit_event({2, 1}, CREATE);
	emit_event({0, 2}, CREATE);
	emit_event({1, 2}, CREATE);
	emit_event({2, 2}, CREATE);

	rl::initWindow(...SCREEN_SIZE, "Game of life on CPU");
	defer rl::closeWindow();
	rl::setTargetFPS(1);
	isz count;

	while (!rl::windowShouldClose())
	{
		rl::@drawing()
		{
			// rl::clearBackground(rl::RAYWHITE);

			usz events = event_queue.len();
			io::printfn("got %s events", events);
			int[EventType.values.len] events1;
			while (events-- > 0)
			{
/*				// event_queue.push({{0, 0}, true});
				// io::printfn("a: %s", events);
				Event event = event_queue.pop_front()!!;
				int[<2>] pos = event.pos;
				// (*back)[pos.y][pos.x] = event.alive;
				// (*front)[pos.y][pos.x] = event.alive;
				foreach (off : NBOR_OFFSETS)
				{
					int[<2>] nbor_pos = mod2(pos + off, GRID_SIZE);
					char n = count_nbors(nbor_pos);
					if ((*back)[nbor_pos.y][nbor_pos.x])
					{
						(*front)[nbor_pos.y][nbor_pos.x] = n == 3 || n == 2;
						// event_queue.push({nbor_pos, n == 3 || n == 2});
						if (n < 2 || n > 3) event_queue.push({nbor_pos, false});
					}
					else
					{
						if (n == 3) event_queue.push({nbor_pos, true});
						(*front)[nbor_pos.y][nbor_pos.x] = n == 3;
					}
				}*/
				Event event = event_queue.pop_front()!!;
				int[<2>] pos = event.pos;
				// io::printfn("event: %s:%s", pos, event.type);
				events1[(int)event.type]++;
				switch (event.type)
				{
					case CREATE:
						// (*back)[pos.y][pos.x] = true;
						(*front)[pos.y][pos.x] = true;
						// nextcase _UPDATE;
						emit_event(pos, _UPDATE);
						nextcase REVIVE;
					case DIE:
						// (*front)[pos.y][pos.x] = false;
						// (*back)[pos.y][pos.x] = false;
						// emit_event(pos, _UPDATE);
						// nextcase _UPDATE;
						foreach (off : NBOR_OFFSETS) emit_event(mod2(pos + off, GRID_SIZE), _UPDATE);
					case REVIVE:
						// (*front)[pos.y][pos.x] = true;
						// (*back)[pos.y][pos.x] = true;
						// emit_event(pos, _UPDATE);
						// nextcase _UPDATE;
						foreach (off : NBOR_OFFSETS) emit_event(mod2(pos + off, GRID_SIZE), _UPDATE);
					case _UPDATE:
						char n = count_nbors(/*back*/front, pos);
						io::printfn("cell at %s has %s neighbours", pos, n);
						if ((*front)[pos.y][pos.x])
						{
							if (n < 2 || n > 3)
							{
								(*front)[pos.y][pos.x] = false;
								emit_event(pos, DIE);
							}
						}
						else
						{
							(*front)[pos.y][pos.x] = true;
							if (n == 3)
							{
								emit_event(pos, REVIVE);
							}
						}
/*						foreach (off : NBOR_OFFSETS)
						{
							int[<2>] nbor_pos = mod2(pos + off, GRID_SIZE);
							char n = count_nbors(/*back*/world, nbor_pos);
							if (world[nbor_pos.y][nbor_pos.x])
							{
								if (n < 2 || n > 3) emit_event(nbor_pos, DIE);
							}
							else
							{
								if (n == 3) emit_event(nbor_pos, REVIVE);
							}
						}*/
				}
			}
			io::printfn("got these events: %s", events1);
			// return 1;

			foreach (int y, &row : front) foreach (int x, cell : row) rl::drawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE, cell ? rl::WHITE : rl::BLACK);
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


// logic:
/*
front: [...]
back: [...]

handle_events()
{}

swap front & back;
*/

// ok actually part of the problem is that i'm mixing together things for swapping the buffers, things for copying the front into the back, and things meant to prevent needing multiple buffers

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
