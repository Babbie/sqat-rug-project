module sqat::series1::A3_CheckStyle

import lang::java::jdt::m3::AST;
import Java17ish;
import Message;
import IO;
import ParseTree;
import util::FileSystem;

/*

Assignment: detect style violations in Java source code.
Select 3 checks out of this list:  http://checkstyle.sourceforge.net/checks.html
Compute a set[Message] (see module Message) containing 
check-style-warnings + location of  the offending source fragment. 

Plus: invent your own style violation or code smell and write a checker.

Note: since concrete matching in Rascal is "modulo Layout", you cannot
do checks of layout or comments (or, at least, this will be very hard).

JPacman has a list of enabled checks in checkstyle.xml.
If you're checking for those, introduce them first to see your implementation
finds them.

Questions
- for each violation: look at the code and describe what is going on? 
  Is it a "valid" violation, or a false positive?

Tips 

- use the grammar in lang::java::\syntax::Java15 to parse source files
  (using parse(#start[CompilationUnit], aLoc), in ParseTree)
  now you can use concrete syntax matching (as in Series 0)

- alternatively: some checks can be based on the M3 ASTs.

- use the functionality defined in util::ResourceMarkers to decorate Java 
  source editors with line decorations to indicate the smell/style violation
  (e.g., addMessageMarkers(set[Message]))

  
Bonus:
- write simple "refactorings" to fix one or more classes of violations 

*/

set[Message] checkStyle(loc project) {
    set[Message] result = {};
  
    visit (crawl(project)) {
        case file(loc l):
            if (l.extension == "java") {
                result = emptyCatchBlock(l, result);
                result = avoidStarImport(l, result);
                result = methodCount(l, result, 30, 30, 30, 30, 30);
                result = publicFields(l, result);
            }
    } 
  
    return result;
}

set[Message] emptyCatchBlock(loc file, set[Message] result) {
    visit (createAstFromFile(file, false)) {
        case c:\catch(_, b:\block([])): {
            result += warning("EmptyCatchBlock", b@src); //Completely empty catch block
        }
        case c:\catch(_, b:\block([\empty()])): {
            result += warning("EmptyCatchBlock", b@src); //Catch block with empty statement (;) Note: not actually required.
        }
    }
    return result;
}

test bool emptyCatchBlock() {
    return emptyCatchBlock(|project://sqat-analysis/src/sqat/test/complex.java|, {}) == 
    {warning("EmptyCatchBlock", |project://sqat-analysis/src/sqat/test/complex.java|(713,6,<47,24>,<48,3>))};
}

set[Message] avoidStarImport(loc file, set[Message] result) {
    visit (parseJava(file)) {
        case i:(ImportDec)`import <PackageName _> .*;`: {
            result += warning("AvoidStarImport", i@\loc); //normal star import
        }
        case i:(ImportDec)`import static <TypeName _> .*;`: {
            result += warning("AvoidStarImport", i@\loc); //static star import
        }
    }
    return result;
}

test bool avoidStarImport() {
    return avoidStarImport(|project://sqat-analysis/src/sqat/test/complex.java|, {}) ==
    {warning("AvoidStarImport", |project://sqat-analysis/src/sqat/test/complex.java|(75,19,<5,0>,<5,19>))};
}

set[Message] methodCount(loc file, set[Message] result, int totalMax, int privateMax, int packageMax, int protectedMax, int publicMax) {
    int totalCount = 0;
    int privateCount = 0;
    int packageCount = 0;
    int protectedCount = 0;
    int publicCount = 0; 
    visit (parseJava(file)) {
        case MethodDecHead mdh: { //for every MethodDecHead
            totalCount += 1; //every methodhead means one method
            if (/(MethodMod)`private` := mdh) privateCount += 1;
            else if (/(MethodMod)`protected` := mdh) protectedCount += 1;
            else if (/(MethodMod)`public` := mdh) publicCount += 1;
            else packageCount += 1; //if no keyword found it's package-level
        }
    }
    
    if (totalCount > totalMax) {
        result += warning("MethodCount Total", file);
    }
    if (privateCount > privateMax) {
        result += warning("MethodCount Private", file);
    }
    if (packageCount > packageMax) {
        result += warning("MethodCount Package", file);
    }
    if (protectedCount > protectedMax) {
        result += warning("MethodCount Protected", file);
    }
    if (publicCount > publicMax) {
        result += warning("MethodCount Public", file);
    }
    return result;
}

test bool methodCount() {
    return methodCount(|project://sqat-analysis/src/sqat/test/complex.java|, {}, 4, 1, 1, 1 ,0) ==
    {warning("MethodCount Public", |project://sqat-analysis/src/sqat/test/complex.java|)};
}

set[Message] publicFields(loc file, set[Message] result) {
    visit (parseJava(file)) {
        case fm:(FieldMod)`public`: result += warning("PublicField", fm@\loc); //we prefer total ecapsulation
    }
    
    return result;
}

test bool publicFields() {
    return publicFields(|project://sqat-analysis/src/sqat/test/complex.java|, {}) ==
    {warning("PublicField", |project://sqat-analysis/src/sqat/test/complex.java|(169,6,<9,1>,<9,7>))};
}