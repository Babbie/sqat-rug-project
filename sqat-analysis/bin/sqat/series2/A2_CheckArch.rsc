module sqat::series2::A2_CheckArch

import lang::java::jdt::m3::AST;
import sqat::series2::Dicto;
import lang::java::jdt::m3::Core;
import Message;
import ParseTree;
import IO;
import Set;

/*

This assignment has two parts:
- write a dicto file (see example.dicto for an example)
  containing 3 or more architectural rules for Pacman
  
- write an evaluator for the Dicto language that checks for
  violations of these rules. 

Part 1  

An example is: ensure that the game logic component does not 
depend on the GUI subsystem. Another example could relate to
the proper use of factories.   

Make sure that at least one of them is violated (perhaps by
first introducing the violation).

Explain why your rule encodes "good" design.
  
Part 2:  
 
Complete the body of this function to check a Dicto rule
against the information on the M3 model (which will come
from the pacman project). 

A simple way to get started is to pattern match on variants
of the rules, like so:

switch (rule) {
  case (Rule)`<Entity e1> cannot depend <Entity e2>`: ...
  case (Rule)`<Entity e1> must invoke <Entity e2>`: ...
  ....
}

Implement each specific check for each case in a separate function.
If there's a violation, produce an error in the `msgs` set.  
Later on you can factor out commonality between rules if needed.

The messages you produce will be automatically marked in the Java
file editors of Eclipse (see Plugin.rsc for how it works).

Tip:
- for info on M3 see series2/A1a_StatCov.rsc.

Questions
- how would you test your evaluator of Dicto rules? (sketch a design)
- come up with 3 rule types that are not currently supported by this version
  of Dicto (and explain why you'd need them). 
  1: Only can would be nice. This way you could specify that only LevelFactory can instantiate Factory
  2: contain dead methods. So you could say that if there are dead methods in test it is not important otherwise it is
  3: Contain empty catch block. Give warning when there is an empty catch block in production code
*/


set[Message] eval(start[Dicto] dicto, M3 m3) = eval(dicto.top, m3);

set[Message] eval((Dicto)`<Rule* rules>`, M3 m3) 
  = ( {} | it + eval(r, m3) | r <- rules );
  
set[Message] eval(Rule rule, M3 m3) {
  set[Message] msgs = {warning("Test", |unknown:///|)};
  
  switch (rule) {
    case (Rule)`<Entity e1> cannot depend <Entity e2>`: msgs = msgs + cannotModality(e1, e2, dependRelation(e1, m3), "depend");
    case (Rule)`<Entity e1> must instantiate <Entity e2>`: msgs = msgs + mustModality(e1, e2, instantiateRelation(e1, m3), "instantiate");
    case (Rule)`<Entity e1> must inherit <Entity e2>`: msgs = msgs + mustModality(e1, e2, inheritRelation(e1, m3), "inherit");
  }
  
  return msgs;
}


rel[loc, loc] importRelation(Entity e, M3 m3){
    // We don't know how to get a project location from an entity, but if we did, it would look like this:
    Declaration AST = createAstsFromFile(e.file, true); 
    rel[loc, loc] result = {};
    visit(AST){
        case \import(name) : result = result = <e, name>;
    }
    return result;
}

rel[loc,loc] dependRelation(Entity e, M3 m3){
    // We don't know how to get a project location from an entity, but if we did, it would look like this:
    return {dependency | dependency <- m3@typeDependency, isClass(dependency.to), dependency.from == e};
}

rel[loc,loc] invokeRelation(Entity e, M3 m3){
    // We don't know how to get a project location from an entity, but if we did, it would look like this:
    return {invocation | invocation <- m3@methodInvocation, invocation.from == e};
}

rel[loc,loc] instantiateRelation(Entity e, M3 m3){
    // We don't know how to get a project location from an entity, but if we did, it would look like this:
    Declaration methodAST = getMethodASTEclipse(e, m3);
    set[str] classes = {};

    visit(methodAST){
        case \newObject(_,_,_,c:Declaration) : {
            classes = classes + c.name;
        }   
        case \newObject(_,_,c:Declaration) : {
            classes = classes + c.name;
        }
    }
    
    return classes;
}

rel[loc,loc] inheritRelation(Entity e, M3 m3){
    // We don't know how to get a project location from an entity, but if we did, it would look like this:
    return {inheritance | inheritance <- (m3@extends + m3@implements), inhertiance.from == e}; 
}

set[Message] mustModality(Entity e1, Entity e2, rel[loc from, loc to] relations, str relationString){
    // We don't know how to get a project location from an entity, but if we did, it would look like this:
    if (size({relation | relation <- relations, relation.to == e2}) == 0) {
        return {warning(relation.e1 + " must " + relationString + " " + relation.e2, relation.e1)};
    }
    return {};
}

set[Message] mayModality(Entity e1, Entity e2, rel[loc from, loc to] relations, str relationString){
    // This does not seem to be any sort of restriction, so it can never be violated.
    return {};
}

set[Message] cannotModality(Entity e1, Entity e2, rel[loc from, loc to] relations, str relationString){
    // We don't know how to get a project location from an entity, but if we did, it would look like this:
    if (size({relation | relation <- relations, relation.to == e2}) > 0) {
        return {warning(relation.e1 + " cannot " + relationString + " " + relation.e2, relation.e1)};
    }
    return {};
}

set[Message] canonlyModality(Entity e1, Entity e2, rel[loc from, loc to] relations, str relationString){
    // We don't know how to get a project location from an entity, but if we did, it would look like this:
    if (size({relation | relation <- relations, relation.to != e2}) > 0) {
        return {warning(relation.e1 + " does not " + relationString + " " + relation.e2, relation.e1)};
    }
    return {};
}