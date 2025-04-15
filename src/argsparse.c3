module args;

import std::core::array;
import std::io;
import std::os;

faultdef 
	PARSE_FAILED,
	ARG_NOT_FOUND,
	EMPTY_SHORT_AND_LONG_NAME,
	EMPTY_DESCRIPTION,
	EXAMPLES_NOT_REQUIRED,
	NON_EMPTY_VALUE_READ,
	NON_FALSE_IS_FOUND,
	INVALID_PROGRAM_NAME;

struct Option
{
    String 	short_name;
    String 	long_name;
    String 	description;
    String 	value_read; 		// from args
	String 	example_value;		// used for errors if is_value_required is set
    bool   	is_required;
	bool 	is_found; 			// is the argument found in args
	bool 	is_value_required; 	// is a value for the argument found in args
}


fn bool? has_arg_short(Option[] options, String name)
{
	foreach(option : options)
    {
        if (name == option.short_name)
        {
            return option.is_found;
        }
    }

    io::eprintfn("Argument '%s' is not defined", name);
    return ARG_NOT_FOUND?;
}

fn bool? has_arg_long(Option[] options, String name)
{
	foreach(option : options)
    {
        if (name == option.long_name)
        {
            return option.is_found;
        }
    }

    io::eprintfn("Argument '%s' is not defined", name);
    return ARG_NOT_FOUND?;
}

fn String? arg_value(Option[] options, String name)
{
    foreach(option : options)
    {
        if (name == option.long_name || name == option.short_name)
        {
            return option.value_read;
        }
    }

    io::eprintfn("Argument '%s' is not defined", name);
    return ARG_NOT_FOUND?;
}

fn String? arg_long_value(Option[] options, String name)
{
    foreach(option : options)
    {
        if (name == option.long_name)
        {
            return option.value_read;
        }
    }

    io::eprintfn("Argument '%s' is not defined", name);
    return ARG_NOT_FOUND?;
}

fn String? arg_short_value(Option[] options, String name)
{
    foreach(option : options)
    {
        if (name == option.short_name)
        {
            return option.value_read;
        }
    }

    io::eprintfn("Argument '%s' is not defined", name);
    return ARG_NOT_FOUND?;
}



fn void? validate_input(Option[] options)
{
    foreach(option : options)
    {
		if(option.short_name == "")
		{
			if(option.long_name == "")
			{
				return EMPTY_SHORT_AND_LONG_NAME?;
			}
		}
		
		if(option.description == "")
		{
			return EMPTY_DESCRIPTION?;
		}
		
		// can't have examples when a value isn't required
		if(option.example_value != "" && !option.is_value_required)
		{
			return EXAMPLES_NOT_REQUIRED?;
		}
		
		if(option.value_read != "")
		{
			return NON_EMPTY_VALUE_READ?;
		}
		
		if(option.is_found == true)
		{
			return NON_FALSE_IS_FOUND?;
		}
			
    }
    return;
}

fn Option[]? parse(
	String[] args, 
	Option[] options, 
	String arg_sep="=",
	bool use_default_help=true,
)
{
	validate_input(options)!;
	
	// iterate through the available options, then we can check for required args
	foreach(&option : options)
    {
        
		foreach(arg_idx, arg : args)
        {
			// program name is the first arg
			if(arg_idx == 0) 
			{
				continue;
			}
			

			// is_short eg -i=4 -j=8
			if (option.short_name != "" && !arg.starts_with("--") && arg.starts_with("-") && arg[1..].starts_with(option.short_name))
			{
				option.is_found = true;
				
				// End of String, No value to read into: value_read
				if(arg.len == (option.short_name.len + "-".len))
				{
					break;
				}
				
				// Non-blank separator, eg --c=44
				if(arg_sep != "")
				{
					// Looking for separator would overflow or reach the end
					usz sep_end = "-".len + option.short_name.len + arg_sep.len;
					if(sep_end >= arg.len)
					{
						break;
					}
					// Read the value after the separator and before the next whitespace
					option.value_read = arg[sep_end..];
				}
				// Blank separator, eg --c44
				else
				{
					// Read the value after short_name and before the next whitespace
					option.value_read = arg[("-".len + option.short_name.len)..];
				}
				
				break;
			}
			
			// is_long eg --ncpus=44
			if (option.long_name != "" && arg.starts_with("--") && arg["--".len..].starts_with(option.long_name))
            {
				option.is_found = true;
				
				// End of String, No value to read into: value_read
				if(arg.len == (option.long_name.len + "--".len))
				{
					break;
				}

				// Non-blank separator, eg --ncpus=44
				if(arg_sep != " ")
				{
					if(arg_sep != "")
					{
						// Looking for separator would overflow or reach the end
						usz sep_end = "--".len + option.long_name.len + arg_sep.len;
						if(sep_end >= arg.len)
						{
							break;
						}
						// Read the value after the separator and before the next whitespace
						option.value_read = arg[sep_end..];
					}
					// Blank separator, eg --ncpus44
					else
					{
						// Read the value after long_name and before the next whitespace
						option.value_read = arg[("--".len + option.long_name.len)..];
					}
				}
				// TODO: handle self.arg_sep == " "
				// TODO: this should check the next arg value if it exists...
				// else
				// {
					
				// }
				
				break;
            }
			
			// Allow overrides to this default help
			if(use_default_help &&  (arg == "--help" || arg == "-h"))
			{
				print_usage(options, args)!;
				return options;
			}
			
			
        }
		
		if(option.is_required && !option.is_found)
		{
			if(option.short_name != "" && option.long_name != "")
			{
				io::eprintfn("Option '--%s' or '-%s' is a required argument", option.long_name, option.short_name);
			}
			else if(option.short_name != "")
			{
				io::eprintfn("Option '-%s' is a required argument", option.short_name);
			}
			else if(option.long_name != "")
			{
				io::eprintfn("Option '--%s' is a required argument", option.long_name);
			}
			
			return PARSE_FAILED?;
		}
		
		if(option.is_value_required && option.value_read == "")
		{	
			if(option.short_name != "" && option.long_name != "")
			{
				io::eprintfn("Option '--%s' or '-%s' must have a value eg '--%s%s%s' or '-%s%s%s'", 
					option.long_name, 
					option.short_name,
					option.long_name,
					arg_sep,
					option.example_value != "" ? option.example_value : "VALUE",
					option.short_name,
					arg_sep,
					option.example_value != "" ? option.example_value : "VALUE",
				);
			}
			else if(option.short_name != "")
			{
				io::eprintfn("Option '-%s' must have a value eg '-%s%s%s'", 
					option.short_name, 
					option.short_name,
					arg_sep,
					option.example_value != "" ? option.example_value : "VALUE",
				);
			}
			else if(option.long_name != "")
			{
				io::eprintfn("Option '--%s' must have a value eg '--%s%s%s'", 
					option.long_name, 
					option.long_name,
					arg_sep,
					option.example_value != "" ? option.example_value : "VALUE",
				);
			}
			
			return PARSE_FAILED?;
		}		
    }
	
	return options;
}



fn String? get_program_name(String[] args)
{
	if(args[0].len == 0)
	{
		return INVALID_PROGRAM_NAME?;
	}
	
	String[] program_split;
	if(args[0].contains("/"))
	{
		program_split = args[0].tsplit("/");
	}
	else if(args[0].contains("\\"))
	{
		program_split = args[0].tsplit("\\");
	}
	else 
	{
		return INVALID_PROGRAM_NAME?;
	}
	
	return program_split[^1];
}

fn void? print_usage(Option[] options, String[] args)
{
	String program_name = get_program_name(args)!;
	
    io::printfn("Usage: %s [OPTIONS]\nOptions:", program_name);

	foreach(option: options)
    {
        if (option.short_name && option.long_name)
        {
            io::printfn("  -%s, --%-10s\t\t%s", option.short_name, option.long_name, option.description);
        } 
		else if (option.long_name)
        {
            io::printfn("      --%-10s\t\t%s", option.long_name, option.description);
        }
		else if (option.short_name)
        {
            io::printfn("  -%s        \t\t\t%s", option.short_name, option.description);
        }
    }
}

