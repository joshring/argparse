module args::testutil;

import std::io;
import libc;

<*
 Prints the values of input1 and input2 if they are found not to be equal, a wrapper for testutil::equal_value with printing
*>
macro bool? equal_value_io(input1, input2, validate_ptr_addr=true, validate_ptr_values=false)
{
	var is_equal = equal_value(
		input1, 
		input2, 
		validate_ptr_addr, 
		validate_ptr_values,
	)!;
	
	if (!is_equal)
	{
		io::printfn("========== input1 and input2 are not equal ==========");
		io::printfn("\ninput1");
		io::printn(input1);
		io::printfn("\ninput2");
		io::printn(input2);
	}
	
	return is_equal;
}

faultdef
	ANY_TYPE_CANNOT_COMPARE_BY_VALUE,
	VOID_TYPE_CANNOT_COMPARE_BY_VALUE,
	UNION_NOT_SUPPORTED,
	BITSTRUCT_NOT_SUPPORTED;


<*
 compare the values of each input, can optionally only compare ptr values, or ptr addresses
 
 @require $typeof(input1) == $typeof(input2) : "the type of input1 must match the type of input2"
*>
macro bool? equal_value(input1, input2, validate_ptr_addr=true, validate_ptr_values=false)
{
	var $Type = $typeof(input1);
	
	$if $typeof(input1).kindof == STRUCT:
	
		$foreach $i, $member : $Type.membersof:

			$switch $member.kindof:
			
				$case SIGNED_INT:
				$case UNSIGNED_INT:
				$case FLOAT:
				$case BOOL:
					if($member.get(input1) != $member.get(input2))
					{
						return false;
					}
				
				
				$case ARRAY:
				$case SLICE:
				
					if ($member.get(input1).len != $member.get(input2).len)
					{
						return false;
					}
					
					foreach (input1_idx, &input1_item : $member.get(input1))
					{
						if ($member.get(input1)[input1_idx] != $member.get(input2)[input1_idx])
						{
							return false;
						}
					}
				
				$case STRUCT:
					
					var inner_equal = equal_value(
						$member.get(input1), 
						$member.get(input2), 
						validate_ptr_addr, 
						validate_ptr_values,
					)!;
					if (inner_equal != true) return false;
					

				$case ANY:
					
					if ($member.get(input1).type != $member.get(input2).type) return false;
					
					if (validate_ptr_addr && 
						$member.get(input1).ptr != $member.get(input2)) return false;
							
					if (validate_ptr_values) return ANY_TYPE_CANNOT_COMPARE_BY_VALUE~;

				$case POINTER:
					
					if ($member.get(input1) == null && $member.get(input2) != null) return false;
					if ($member.get(input1) != null && $member.get(input2) == null) return false;
					
					if (validate_ptr_addr)
					{
						if ($member.get(input1) != $member.get(input2))
						{
							return false;
						}
					}
					
					if (validate_ptr_values)
					{
						var $InnerType = $typeof($member.get(input1));

						// recursively check equality (skip void pointers)
						$if $InnerType.inner.kindof != VOID:
							if (!equal_value(*$member.get(input1), *$member.get(input2))!) return false;
						$else
							return VOID_TYPE_CANNOT_COMPARE_BY_VALUE~;
						$endif
					}
				
				// Returning a fault as cannot be supported
				// Create a type which excludes these to compare
				$case UNION:
					return UNION_NOT_SUPPORTED~;
					
				$case BITSTRUCT:
					return BITSTRUCT_NOT_SUPPORTED;

			$endswitch
			
		$endforeach

	$endif;
	
	return true;
}

struct ExampleNested
{
	int int_nested;
	int* int_nested_ptr;
}

bitstruct BsEx : char
{
	int x : 0..3;
	int y : 4..7;
}

union UnionEx
{
	char 	as_byte;
	short 	as_short;
	int 	as_int;
	uint 	as_uint;
	long 	as_long;
	ulong 	as_ulong;
	int128 	as_int128; 	// 128bit
	uint128 as_uint128; // 128bit
}

struct Example
{
	String[] 		str_sl_val;
	String 			str_val;
	String* 		str_ptr;
	float[] 		float_sl_val;
	float 			float_val;
	float* 			float_ptr;
	long[] 			long_sl_val;
	long 			long_val;
	long* 			long_ptr;
	int[] 			int_sl_val;
	int 			int_val;
	int* 			int_ptr;
	uint[] 			uint_sl_val;
	uint 			uint_val;
	uint* 			uint_ptr;
	bool[] 			bool_sl_val;
	bool 			bool_val;
	bool* 			bool_ptr;
	void* 			void_ptr;
	any 			any_val;
	// ExampleNested 	example_nested;
	// BsEx 			example_bitstruct;
	// UnionEx 		example_union;
	// int[<2>] 		int_vec;
	// int*[<2>]		int_ptr_vec;
	// float[<2>] 		float_vec;
	// float*[<2>]		float_ptr_vec;
	
}


fn void test_equal_value() @test
{
	String 	str_point_to = "EXAMPLE";
	float 	float_point_to = 4.1;
	long 	long_point_to = 44;
	int 	int_point_to = 22;
	uint 	uint_point_to = 24;
	bool 	bool_point_to = true;
	void* 	void_ptr = (void*)&int_point_to;
	// any 	any_value = any_make(&int_point_to, int.typeid);
	
	
		
	Example ex = {
		.str_sl_val		= {"a", "b"},
		.str_val		= "example",
		.str_ptr		= &str_point_to,
		.float_sl_val	= {1.1, 2.2},
		.float_val		= 5.5,
		.float_ptr		= &float_point_to,
		.long_sl_val	= {22, 44, 128},
		.long_val		= 44,
		.long_ptr		= &long_point_to,
		.int_sl_val		= {1,2,4},
		.int_val		= 44,
		.int_ptr		= &int_point_to,
		.uint_sl_val	= {12, 44},
		.uint_val		= 44,
		.uint_ptr		= &uint_point_to,
		.bool_sl_val	= {true, false, true},
		.bool_val		= true,
		.bool_ptr		= &bool_point_to,
		.void_ptr		= void_ptr,
		.any_val 		= any_make(&int_point_to, int.typeid), 
		// .example_nested=
		// .example_bitstruct=
		// .example_union=
		// .int_vec=
		// .int_ptr_vec=
		// .float_vec=
		// .float_ptr_vec=
	};
	Example ex2 = ex;
	ex2.int_val = 999999999;
	
	// validate_ptr_addr: false, validate_ptr_values: false
	
	assert(equal_value(ex, ex2)!! == false, "int_val was changed");
	
	Example ex3 = ex;
	ex3.str_ptr = &&"temp string";
	assert(equal_value(ex, ex3)!! == false, "str_ptr was changed");

	Example ex4 = ex;
	ex4.float_sl_val = {6.6, 4.4};
	assert(equal_value(ex, ex4)!! == false, "float_sl_val was changed");
	
	Example ex5 = ex;
	ex5.void_ptr = &ex4;
	assert(
		equal_value(ex, ex5)!! == false, 
		"void_ptr was changed"
	);
	
	assert(
		equal_value(
			ex, 
			ex5, 
			validate_ptr_values: false,
		)!! == false, "void_ptr was changed, reading value disabled"
	);
		
	assert(
		equal_value(
			ex,
			ex5,
			validate_ptr_addr: false,
		)!! == true, "void_ptr was changed, but pointer address check disabled so should be the same"
	);
		
	assert(
		equal_value(
			ex, 
			ex5, 
			validate_ptr_addr: false,
			validate_ptr_values: false,
		)!! == true, "void_ptr was changed, but pointer checks disabled should be the same"
	);
	
	//=========================================
	
	Example ex6 = ex;
	int any_test = 66;
	// ex6.any_val = any_make(&ex4, Example.typeid);
	ex6.any_val = &any_test;
	assert(
		equal_value(ex, ex6)!! == false, 
		"any_val was changed"
	);

	
	
	// ContainsAny a = { .field = any_make(&&2, int.typeid) };
	// ContainsAny b = { .field = any_make(&&2, int.typeid) };
	
	// assert(a.field.typeid == b.field.typeid, "this should work");
	
	// assert(equal_value(ex, ex2));
	
	// unreachable("show logs pls");
}

