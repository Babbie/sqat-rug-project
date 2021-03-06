module sqat::series1::A1_SLOC

import IO;
import util::FileSystem;
import String;
import List;
import Map;

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
  |project://jpacman-framework/src/main/java/nl/tudelft/jpacman/level/Level.java| (179 SLOC)
- what is the total size of JPacman?
  2458 SLOC
- is JPacman large according to SIG maintainability?
  No, as it falls under the extremely small category, which ranges from 0 to 66.000 SLOC.
- what is the ratio between actual code and test code size?
  main: 1901 SLOC, test: 557, ratio: ~3.4

Sanity checks:
- write tests to ensure you are correctly skipping multi-line comments
- and to ensure that consecutive newlines are counted as one.
- compare you results to external tools sloc and/or cloc.pl

Bonus:
- write a hierarchical tree map visualization using vis::Figure and 
  vis::Render quickly see where the large files are. 
  (https://en.wikipedia.org/wiki/Treemapping) 

*/

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
    list[str] lines = readFileLines(file);
    lines = emptyStrings(lines);
    lines = removeBlockComments(lines);
    lines = removeSingleComments(lines); // also removes empty/whitespace lines
    return size(lines);
}

list[str] emptyStrings(list[str] lines) {
    list[str] result = [];
    for (str line <- lines) {
        str newLine = "";
        bool inQuotes = false;
        bool inBlockComment = false;
        bool escape = false;
        for (int i <- [0..size(line)]) { //look at each character
            if (inBlockComment) {
                newLine += line[i];
                if (i + 1 < size(line) && line[i] == "*" && line[i+1] == "/") {
                    inBlockComment = false; //end of comment block, quotes count again
                }
            } else if (!inQuotes) {
                if (i + 1 < size(line) && line[i] == "/" && line[i+1] == "*") {
                    inBlockComment = true; //start of comment block, just copy until end
                    newLine += line[i];
                } else if (escape) {
                    newLine += "_"; //escape character
                    escape = false;
                } else if (line[i] == "\\") {
                    escape = true; //escaping
                } else if (line[i] == "\"") {
                    inQuotes = true; //start of string
                    newLine += "_";
                } else {
                    newLine += line[i]; //outside of string, so copy
                }
            } else {
                if (escape) {
                    escape = false; //ignore escaped character
                } else if (line[i] == "\\") {
                    escape = true; //escaping
                } else if (line[i] == "\"") {
                    inQuotes = false; //end of string
                }
            }
        }
        result += newLine;
    }
    return result;
}

list[str] removeBlockComments(list[str] lines) {
    list[str] result = [];
    bool inBlock = false;
    for (str line <- lines) {
        bool inSingleComment = false;
        bool skip = false;
        str newLine = "";
        for (int i <- [0..size(line)]) { //look at each character
            if (i + 1 < size(line) && line[i] == "/" && line[i+1] == "/") { //if single line comment
                if (!inBlock) { //not in block, just copy
                    newLine += line[i];
                }
                inSingleComment = true; //blocks don't count in a single line comment
            } else if (skip) {
                skip = false; //second character of block comment delimiters
            } else if (!inBlock) {
                if (!inSingleComment, i + 1 < size(line), line[i] == "/", line[i+1] == "*") { //block start
                    skip = true; //skip second character
                    inBlock = true; //we're now in a comment block
                } else {
                    newLine += line[i]; //we're not in a comment block, so copy
                }
            } else {
                if (i + 1 < size(line) && line[i] == "*" && line[i+1] == "/") { //block end
                    skip = true; //skip second character
                    inBlock = false; //no longer in a comment block
                }//ignore other contents of comment block
            }
        }
        result += newLine;
    }
    return result;
}

list[str] removeSingleComments(list[str] lines) {
    list[str] result = [];
    for (str line <- lines) {
        str newLine = "";
        for (int i <- [0..size(line)]) { //look at each character
            if (i + 1 < size(line) && line[i] == "/" && line[i+1] == "/") {
                break; //if double slashes, ignore rest of line
            } else {
                newLine += line[i];
            }
        }
        if (trim(newLine) != "") {
            result += newLine; //if the trimmed result is empty, it's not a SLOC
        }
    }
    return result;
}

test bool jPacman() {
    SLOC result = sloc(|project://jpacman-framework/src|);
    int sum = 0;
    for (file <- result) {
        sum += result[file];
    }
    return sum == 2458;
}

test bool ourCase() {
    SLOC result = sloc(|project://sqat-analysis/src/sqat/test/comments.java|);
    int sum = 0;
    for (file <- result) {
        sum += result[file];
    }
    return sum == 15;
}