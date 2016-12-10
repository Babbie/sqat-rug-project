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
        bool escape = false;
        for (str char <- split("", line)) { //look at each character
            if (!inQuotes) {
                if (escape) {
                    newLine += "_";
                    escape = false;
                } else if (char == "\\") {
                    escape = true;
                } else if (char == "\"") {
                    inQuotes = true;
                    newLine += "_";
                } else {
                    newLine += char;
                }
            } else {
                if (escape) {
                    escape = false;
                } else if (char == "\\") {
                    escape = true;
                } else if (char == "\"") {
                    inQuotes = false;
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
        bool skip = false;
        str newLine = "";
        for (int i <- [0..size(line)]) { //look at each character
            if (skip) {
                skip = false;
                continue;
            } else if (!inBlock) {
                if (i + 1 < size(line) && line[i] == "/" && line[i+1] == "*") {
                    skip = true;
                    inBlock = true;
                } else {
                    newLine += line[i];
                }
            } else {
                if (i + 1 < size(line) && line[i] == "*" && line[i+1] == "/") {
                    skip = true;
                    inBlock = false;
                }
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
                break;
            } else {
                newLine += line[i];
            }
        }
        if (trim(newLine) != "") {
            result += newLine;
        }
    }
    return result;
}

test bool jPacman() {
    SLOC result = sloc(|project://jpacman-framework/src|);
    int sum = (sloc : result[sloc] | sloc <- result);
    return sum == 2458;
}

test bool ourCase() {
    SLOC result = sloc(|project://sqat-analysis/src/sqat/test/comments.java|);
    int sum = sum(result.sloc);
    return sum == 22;
}