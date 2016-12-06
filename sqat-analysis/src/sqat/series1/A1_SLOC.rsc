module sqat::series1::A1_SLOC

import IO;
import util::FileSystem;

/* 

Count Source Lines of Code (SLOC) per file:
- ignore comments
- ignore empty lines

Tips
- use locations with the project scheme: e.g. |project:///jpacman/...|
- functions to crawl directories can be found in util::FileSystem
- use the functions in IO to read source files

Answer the following questions:
- what is the biggest file in JPacman?
- what is the total size of JPacman?
- is JPacman large according to SIG maintainability?
- what is the ratio between actual code and test code size?

Sanity checks:
- write tests to ensure you are correctly skipping multi-line comments
- and to ensure that consecutive newlines are counted as one.
- compare you results to external tools sloc and/or cloc.pl

Bonus:
- write a hierarchical tree map visualization using vis::Figure and 
  vis::Render quickly see where the large files are. 
  (https://en.wikipedia.org/wiki/Treemapping) 

*/

start syntax Source
    = Line* lines Text? lastLine;
   
lexical Newline
    = "\n";
    
syntax Line
    = Text Newline;
    
lexical Text
    = ![\n];

alias SLOC = map[loc file, int sloc];

SLOC sloc(loc project) {
    SLOC result = ();
    
    top-down visit(crawl(project)) {
        case file(loc l):
            if (l.extension == "java") {
                result[l] = countSLOC(l);
            }
    }
    return result;
}

int countSLOC(loc file) {
    return 12;
}

void testo(loc file) {
    start[Source] commentless = parse(#start[Source], file);
    top-down visit(commentless) {
        case CommentBlocks t:
        {
            println("HOI: "+ t);
        }
    }
}
/* /* hoi */