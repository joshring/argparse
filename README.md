# argparse
C3 Argparse

```c
module main;
import std::io;
import args;

fn void main(String[] args)
{
	io::printfn(
		"\nArgs provided to the program\n"
		"============================="
	);
	foreach(arg : args)
	{
		io::printn(arg);
	}

		
	Option[]? options_read = args::parse(
		args: args,
		// argument separator, usually whitespace " " or "="
		arg_sep: " ",
		// arg_sep: "=",
		options: {
			// A long and short name, with a required associated value
			{
				.valid_values={"true", "false"},
				.short_name="r",
				.long_name="required",
				.description="required arg",
				.example_value="EXAMPLE",
				.is_required=true,
				.is_value_required=true,
			},
			// An optional, long and short name, with a required associated value (when provided)
			{
				.valid_values={},
				.short_name="d",
				.long_name="description",
				.description="optional description",
				.example_value=`"description here"`,
				.is_required=false,
				.is_value_required=true,
			},
			// A single value flag or toggle without an associated value
			{
				.short_name="n",
				.long_name="not_required",
				.description="optional arg",
				.example_value="",
				.is_required=false,
				.is_value_required=false,
			},
		}
	);
	if(catch err = options_read)
	{
		io::printn(err);
		return;
	}
	
	io::printfn(
		"\nOptions parsed by the program\n"
		"============================="
	);
	foreach(option : options_read)
	{
		io::printn(option);
		io::printn();
	}
}
```