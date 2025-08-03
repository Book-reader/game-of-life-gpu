module game_of_life;
import raylib5::rl;
import std::io;
import std::collections::linkedlist;
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

LinkedList {int[2]} event_queue;
LinkedList {int[2]} next_queue;


macro emit_event(int[<2>] pos) => next_queue.push(pos);

fn int main(String[] args)
{
	// this allocator stuff is a desparate attempt to reduce the cost of allocating each event in the heap
	// idk if it actually makes much of a difference though
	char[] _mem = mem::new_array(char, 200 * mem::MB);
	char[] _mem1 = mem::new_array(char, 200 * mem::MB);
	defer mem::free(_mem);
	defer mem::free(_mem1);
	ArenaAllocator* alloc = allocator::wrap(_mem);
	ArenaAllocator* alloc1 = allocator::wrap(_mem1);

	event_queue.init(alloc);
	next_queue.init(alloc1);
	defer event_queue.free();
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

	// initial alive count
	usz alive;
	foreach (int y, &row : back) foreach (int x, cell : row) if (cell.alive) alive ++;

	rl::initWindow(...SCREEN_SIZE, "Game of life on CPU");
	defer rl::closeWindow();
	rl::setTargetFPS(60);

	RenderTexture tex = rl::loadRenderTexture(...SCREEN_SIZE);
	defer rl::unloadRenderTexture(tex);

	while (!rl::windowShouldClose()) rl::@drawing()
	{
		@swap(event_queue, next_queue);
		@swap(alloc, alloc1);
		alloc1.clear();

		rl::@textureMode(tex)
		{
			while (try int[<2>] pos = event_queue.pop_front())
			{
				rl::drawRectangle(...pos * CELL_SIZE, CELL_SIZE, CELL_SIZE, back.get(pos).alive ? rl::WHITE : rl::BLACK);
				foreach (off : OFFSETS)
				{
					int[<2>] pos1 = mod2(pos + off, GRID_SIZE);
					char n = count_nbors(back, pos1);

					(*back)[pos1.y][pos1.x].notified = false;

					if (back.get(pos1).alive)
					{
						(*front)[pos1.y][pos1.x].alive = n == 2 || n == 3;
					}
					else
					{
						(*front)[pos1.y][pos1.x].alive = n == 3;
					}
					if (front.get(pos1).notified == false && front.get(pos1).alive != back.get(pos1).alive)
					{
						alive += front.get(pos1).alive ? 1 : -1;
						(*front)[pos1.y][pos1.x].notified = true;
						emit_event(pos1);
					}
				}
			}
		};
		alloc.clear();

		rl::clearBackground(rl::BLACK);
		// I have to draw to this texture to prevent flickering issues, and I use -SCREEN_SIZE.y because rendering to textures is flipped vertically for some reason
		rl::drawTextureRec(tex.texture, {0, 0, SCREEN_SIZE.x, -SCREEN_SIZE.y}, {0, 0}, rl::WHITE);

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
