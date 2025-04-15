module main;
import std::io;
import args;

fn void main(String[] args)
{
	io::printfn("arguments: %s", args);
		
	Option[] options = args::parse(
		args: args,
		options: {
			{
				.short_name="r",
				.long_name="required",
				.description="this needs to be here",
				// .value_read="",
				.example_value="EXAMPLE",
				.is_required=true,
				// .is_found=false,
				.is_value_required=true,
			},
			{
				.short_name="n",
				.long_name="not_required",
				.description="this doesn't need to be here",
				// .value_read="",
				.example_value="",
				.is_required=false,
				// .is_found=false,
				.is_value_required=false,
			}
		}
		)!!;
	
	io::printn(options[0]);
	args::print_usage(options, args)!!;
	
	io::printfn("has_arg_short: %s", args::has_arg_short(options, "r"))!!;
	io::printfn("has_arg_long: %s", args::has_arg_long(options, "required"))!!;
	
	io::printfn("arg_short_value: %s", args::arg_short_value(options, "r"))!!;
	io::printfn("arg_long_value: %s", args::arg_long_value(options, "required"))!!;
	
	io::printfn("arg_value: %s", args::arg_value(options, "r"))!!;
	io::printfn("arg_value: %s", args::arg_value(options, "required"))!!;	
}