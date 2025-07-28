module load;
import std::collections::list;

alias Chars = List {char};

fn char[][] decode(Allocator alloc, String data) => @pool()
{
	List {Chars} chars;
	String[] split = data.tsplit("\n");
	foreach (i, line : split)
	{
		if (line.len == 0 || line[0] == '!') continue;
		chars.push({});
		foreach (ch : line)
		{
			switch (ch)
			{
				case '.':
					chars[^1].push(0);
				case 'O':
					chars[^1].push(255);
				default:
					abort("unexpected char '%c'", ch);
			}
		}
	}

	char[][] res = allocator::alloc_array(alloc, char[], chars.len());
	foreach (i, &val : res)
	{
		*val = chars[i].to_array(alloc);
	}
	return res;
}

