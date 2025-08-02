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
const int CELL_SIZE = 10; // 2;

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
LinkedList {Event} event_queue;

HashMap {int, HashMap {int, bool}} a;

macro emit_event(int[<2>] pos, EventType type) => event_queue.push({pos, type});

struct Modification // @packed
{
	int[2] pos;
	bool alive;
}

/*Linked*/List {Modification} modification_queue;

macro set(int[<2>] pos, bool alive) => modification_queue.push({pos, alive});

fn int main(String[] args)
{
	event_queue.init(mem);
	defer event_queue.free();
	modification_queue.init(mem);
	defer modification_queue.free();

	// foreach (uint y, &row : back) foreach (uint x, cell : row) (*back)[y][x] = rnd() > 0.5;
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
	(*back)[0][1].alive = true;
	(*back)[1][2].alive = true;
	(*back)[2][0].alive = true;
	(*back)[2][1].alive = true;
	(*back)[2][2].alive = true;
/*	set({1, 0}, true);
	set({2, 1}, true);
	set({0, 2}, true);
	set({1, 2}, true);
	set({2, 2}, true);*/

	// for (int x = 0; x < GRID_SIZE.x; x++) for (int y = 0; y < GRID_SIZE.y; y++) emit_event({x, y}, _UPDATE);

	rl::initWindow(...SCREEN_SIZE, "Game of life on CPU");
	defer rl::closeWindow();
	rl::setTargetFPS(1);

	while (!rl::windowShouldClose()) rl::@drawing()
	{
		// while (try n = modification_queue._first);
/*		usz modifiations = modification_queue.len();
		while (modifiations-- > 0)
		{
			Modification modifiation = modification_queue.pop_front()!!;
			modification_queue.push(modifiation); // so I can reuse them. TODO: find some way to not have to do this
			(*back)[modifiation.pos[1]][modifiation.pos[0]] = modifiation.alive;
		}
		foreach (modifiation : modification_queue)
		{
			(*back)[modifiation.pos[1]][modifiation.pos[0]].alive = modifiation.alive;
		}
		foreach (modifiation : modification_queue)
		{
			int[<2>] pos = modifiation.pos;
			char n = count_nbors(back, pos);
			if ((*back)[pos.y][pos.x].alive)
			{
				(*front)[pos.y][pos.x] = {n == 2 || n == 3, false};
			}
			else
			{
				(*front)[pos.y][pos.x] = {n == 3, false};
			}
			// (*back)[pos.y][pos.x].notified = true;
			if ((*front)[pos.y][pos.x] != (*back)[pos.y][pos.x])
			{
				foreach (off : NBOR_OFFSETS)
				{
					int[<2>] nbor_pos = mod2(pos + off, GRID_SIZE);
					if (!(*front)[pos.y][pos.x].notified)
				}
			}
		}
		modification_queue.clear();*/
/*		HashSet {int[<2>]} notified;
		notified.init(mem);
		defer notified.free();*/

		usz events = event_queue.len();
		io::printfn("got %s events", events);
		while (events-- > 0)
		{
			Event event = event_queue.pop_front()!!;
			int[<2>] pos = event.pos;
			foreach (off : OFFSETS)
			{
				int[<2>] pos1 = mod2(pos + off, GRID_SIZE);
				char n = count_nbors(back, pos1);
				// notified.add(pos1);

				(*back)[pos1.y][pos1.x].notified = false;

				if (back.get(pos1).alive)
				{
					// front.set(pos1, {n == 2 || n == 3, false});
					(*front)[pos1.y][pos1.x].alive = n == 2 || n == 3;
				}
				else
				{
					// front.set(pos1, {n == 3, false});
					(*front)[pos1.y][pos1.x].alive = n == 3;
				}
				if (front.get(pos1).alive != back.get(pos1).alive && front.get(pos1).notified == false)
				{
					(*front)[pos1.y][pos1.x].notified = true;
					emit_event(pos1, _CHANGED);
				}
			}
		}
/*		notified.@each(; val)
		{
			io::printfn("%s", val);
		};*/

		usz count;
		// rl::clearBackground(rl::RAYWHITE);
/*
		usz events = event_queue.len();
		io::printfn("got %s events", events);
		while (events-- > 0)
		{
			Event event = event_queue.pop_front()!!;
			int[<2>] pos = event.pos;
			// if ((*back)[pos.y][pos.x].notified) continue;
/*			(*back)[pos.y][pos.x].notified = false;

			char n = count_nbors(back, pos);
			if ((*back)[pos.y][pos.x].alive)
			{
				(*front)[pos.y][pos.x] = {n == 2 || n == 3, false};
			}
			else
			{
				(*front)[pos.y][pos.x] = {n == 3, false};
			}
			if ((*back)[pos.y][pos.x].alive != (*front)[pos.y][pos.x].alive) // emit_event(pos, _UPDATE);
			{
				for (int x = -1; x <= 1; x++) for (int y = -1; y <= 1; y++)
				{
			//		emit_event((*back));
				}
			}*/
			emit_event(pos, _UPDATE);
			for (int x = -1; x <= 1; x++) for (int y = -1; y <= 1; y++)
			{
				int[<2>] nbr_pos = {mod(pos.x + x, GRID_SIZE.x), mod(pos.y + y, GRID_SIZE.y)};

				if ((*back)[nbr_pos.y][nbr_pos.x].notified) continue;
				(*back)[nbr_pos.y][nbr_pos.x].notified = true;

				char n = count_nbors(back, nbr_pos);
				if ((*back)[nbr_pos.y][nbr_pos.x].alive)
				{
					(*front)[nbr_pos.y][nbr_pos.x] = {n == 3 || n == 2, false};
				}
				else
				{
					(*front)[nbr_pos.y][nbr_pos.x] = {n == 3, false};
				}
				// emit_event(nbr_pos, _UPDATE);
			}
		}
*/
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

		foreach (int y, &row : back) foreach (int x, cell : row) rl::drawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE, cell ? rl::WHITE : rl::BLACK);
		rl::drawFPS(20, 20);
		@pool()
		{
			rl::drawText(string::tformat_zstr("%s alive cells", count), 20, 50, 20, rl::LIGHTGRAY);
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
