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
const int CELL_SIZE = 1;

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
/*bitstruct Cell : char
{
	bool alive;
	bool notified;
}*/
struct Cell
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
LinkedList {int[2]} next_queue;

HashMap {int, HashMap {int, bool}} a;

macro emit_event(int[<2>] pos) => next_queue.push(pos);

fn int main(String[] args)
{

	char[] _mem = mem::new_array(char, 200 * mem::MB);
	defer mem::free(_mem);
	ArenaAllocator* alloc = allocator::wrap(_mem);
	char[] _mem1 = mem::new_array(char, 200 * mem::MB);
	defer mem::free(_mem1);
	ArenaAllocator* alloc1 = allocator::wrap(_mem1);
	event_queue.init(alloc);
	defer event_queue.free();
	next_queue.init(alloc1);
	defer next_queue.free();

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
	// foreach (int y, &row : back) foreach (int x, cell : row) emit_event({x, y});
	usz alive;
	foreach (int y, &row : back) foreach (int x, cell : row) if (cell.alive) alive ++;

	rl::initWindow(...SCREEN_SIZE, "Game of life on CPU");
	defer rl::closeWindow();
	rl::setTargetFPS(60);

	RenderTexture tex = rl::loadRenderTexture(...SCREEN_SIZE);
	defer rl::unloadRenderTexture(tex);
	// isz alive;
	while (!rl::windowShouldClose()) rl::@drawing()
	{
		@swap(event_queue, next_queue);
		@swap(alloc, alloc1);
		alloc1.clear();
		// rl::clearBackground(rl::BLACK);
		// usz alive;// = event_queue.len();
		// io::printfn("got %s events", event_queue.len());
		rl::@textureMode(tex)
		{
			while (try int[<2>] pos = event_queue.pop_front())
			{
				// rl::drawRectangle(...pos * CELL_SIZE, CELL_SIZE, CELL_SIZE, /*(*back)[pos.y][pos.x].alive ? rl::WHITE : rl::BLACK*/rl::GREEN);
				// rl::drawRectangle(pos.x * CELL_SIZE, pos.y * CELL_SIZE, CELL_SIZE, CELL_SIZE, rl::RED);
				// rl::drawRectangle(pos.x * CELL_SIZE, pos.y * CELL_SIZE, CELL_SIZE, CELL_SIZE, back.get(pos).alive ? rl::WHITE : rl::BLACK);
				rl::drawRectangle(...pos * CELL_SIZE, CELL_SIZE, CELL_SIZE, back.get(pos).alive ? rl::WHITE : rl::BLACK);
				foreach (off : OFFSETS)
				{
					int[<2>] pos1 = mod2(pos + off, GRID_SIZE);
					char n = count_nbors(back, pos1);
					// defer rl::drawRectangle(...pos1 * CELL_SIZE, CELL_SIZE, CELL_SIZE, (*front)[pos1.y][pos1.x].alive ? rl::WHITE : rl::BLACK);
					// rl::drawRectangle(...pos1 * CELL_SIZE, CELL_SIZE, CELL_SIZE, {0, 255, 0, 80});
					// notified.add(pos1);

					(*back)[pos1.y][pos1.x].notified = false;

					if (back.get(pos1).alive)
					{
						(*front)[pos1.y][pos1.x].alive = n == 2 || n == 3;
						// if (n < 2 || n > 3) alive --;
					}
					else
					{
						(*front)[pos1.y][pos1.x].alive = n == 3;
						// if (n == 3) alive ++;
					}
					// rl::drawRectangle(...pos * CELL_SIZE, CELL_SIZE, CELL_SIZE, front.get(pos1).alive ? rl::WHITE : rl::BLACK);
					if (front.get(pos1).notified == false && front.get(pos1).alive != back.get(pos1).alive)
					{
						alive += front.get(pos1).alive ? 1 : -1;
						(*front)[pos1.y][pos1.x].notified = true;
						emit_event(pos1);
					}
					// if (off == {0, 0}) rl::drawRectangle(...pos1 * CELL_SIZE, CELL_SIZE, CELL_SIZE, front.get(pos1).alive ? rl::WHITE : rl::BLACK);
				}
				// rl::drawRectangle(...pos * CELL_SIZE, CELL_SIZE, CELL_SIZE, (*back)[pos.y][pos.x].alive ? rl::WHITE : rl::BLACK);
			}
		};
		rl::clearBackground(rl::BLACK);
		rl::drawTextureRec(tex.texture, {0, 0, SCREEN_SIZE.x, -SCREEN_SIZE.y}, {0, 0}, rl::WHITE);
		alloc.clear();
/*		foreach (int y, &row : back) foreach (int x, cell : row)
		{
			char n = count_nbors(back, {x, y});
			rl::drawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE, cell.alive ? rl::WHITE : rl::BLACK);
			if ((*back)[y][x].alive)
			{
				// alive ++;
				// rl::drawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE, rl::WHITE);
				(*front)[y][x].alive = n == 3 || n == 2;
			}
			else
			{
				(*front)[y][x].alive = n == 3;
			}
		}*/

/*		foreach (int y, &row : back) foreach (int x, cell : row)
		{
			alive += (usz)cell.alive;
			const OPACITY = 80;
			rl::drawRectangle(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE, cell.alive ? {255, 0, 0, OPACITY} : {0, 0, 0, OPACITY});
		}*/
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
		if ((*world)[mod(pos.y + off.y, GRID_SIZE.y)][mod(pos.x + off.x, GRID_SIZE.x)].alive) c++;
	}
	return c;
}
