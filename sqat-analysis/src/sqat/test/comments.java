package sqat.test;

public class comments { //this class has all different kinds of comments in it in various situations
	// for example this line has no code
	/* nor does this one */
	/* this one spans multiple lines
	 * like this, see?
	 */
	public int /* this should also be counted as code */ test;
	/* so should this*/ public int test2;
	public String annoying = "/*";
	public int test3; //these should all be counted as code
	public String annoying2 = "*/";
	
	public int test4; /* this is pretty strange
	but it also works*/ public int test5; /* who even comments like
	this */ public int test6;
	/* heya */ public int test7; /* weirdness */
	
	// this line won't work well /*
	
	public int test8;
	
	// */
	
	/* but this one does! // */ public int test9;
	
	/* this line gets deleted " */ public int test10; /* " */
}