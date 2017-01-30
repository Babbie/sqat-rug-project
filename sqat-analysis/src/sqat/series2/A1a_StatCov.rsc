module sqat::series2::A1a_StatCov

import lang::java::jdt::m3::Core;
import Set;

/*

Implement static code coverage metrics by Alves & Visser 
(https://www.sig.eu/en/about-sig/publications/static-estimation-test-coverage)


The relevant base data types provided by M3 can be found here:

- module analysis::m3::Core:

rel[loc name, loc src]        M3@declarations;            // maps declarations to where they are declared. contains any kind of data or type or code declaration (classes, fields, methods, variables, etc. etc.)
rel[loc name, TypeSymbol typ] M3@types;                   // assigns types to declared source code artifacts
rel[loc src, loc name]        M3@uses;                    // maps source locations of usages to the respective declarations
rel[loc from, loc to]         M3@containment;             // what is logically contained in what else (not necessarily physically, but usually also)
list[Message]                 M3@messages;                // error messages and warnings produced while constructing a single m3 model
rel[str simpleName, loc qualifiedName]  M3@names;         // convenience mapping from logical names to end-user readable (GUI) names, and vice versa
rel[loc definition, loc comments]       M3@documentation; // comments and javadoc attached to declared things
rel[loc definition, Modifier modifier] M3@modifiers;     // modifiers associated with declared things

- module  lang::java::m3::Core:

rel[loc from, loc to] M3@extends;            // classes extending classes and interfaces extending interfaces
rel[loc from, loc to] M3@implements;         // classes implementing interfaces
rel[loc from, loc to] M3@methodInvocation;   // methods calling each other (including constructors)
rel[loc from, loc to] M3@fieldAccess;        // code using data (like fields)
rel[loc from, loc to] M3@typeDependency;     // using a type literal in some code (types of variables, annotations)
rel[loc from, loc to] M3@methodOverrides;    // which method override which other methods
rel[loc declaration, loc annotation] M3@annotations;

Tips
- encode (labeled) graphs as ternary relations: rel[Node,Label,Node]
- define a data type for node types and edge types (labels) 
- use the solve statement to implement your own (custom) transitive closure for reachability.

Questions:
- what methods are not covered at all?
- how do your results compare to the jpacman results in the paper? Has jpacman improved?
- use a third-party coverage tool (e.g. Clover) to compare your results to (explain differences)


*/

data Node
    = package(loc location)
    | class(loc location, bool testCode)
    | interface(loc location, bool testCode)
    | method(loc location, bool testCode);
    
data Edge
    = definesType()
    | definesMethod()
    | calls()
    | virtualCalls();
    // overloading calls not needed, rascal covers this for us
    
alias Graph = rel[Node, Edge, Node];

M3 jpacmanM3() = createM3FromEclipseProject(|project://jpacman-framework|);
M3 jpacmanTestM3() = createM3FromDirectory(|file:///C:/Users/Bab/git/sqat-rug-project/jpacman/src/test|);

num getSystemCoverage(M3 m3, M3 testm3) {
    Graph graph = createGraph(m3, testm3);
    set[Node] coveredMethods = collectCoveredMethods(graph);
    num numOfDefinedMethods = 0.0;
    num numOfCoveredMethods = 0.0;
    
    for (class <- classes(m3) - classes(testm3)) {
        tuple[num defined, num covered] results = getFundamentalMetricsForClass(graph, class, coveredMethods);
        numOfDefinedMethods = numOfDefinedMethods + results.defined;
        numOfCoveredMethods = numOfCoveredMethods + results.covered;
    }
    
    return (numOfCoveredMethods / numOfDefinedMethods) * 100;
}

num getClassCoverage(M3 m3, M3 testm3, loc class) {
    Graph graph = createGraph(m3, testm3);
    set[Node] coveredMethods = collectCoveredMethods(graph);

    tuple[num defined, num covered] results = getFundamentalMetricsForClass(graph, class, coveredMethods);
    num numOfDefinedMethods = results.defined;
    num numOfCoveredMethods = results.covered;
    
    return numOfDefinedMethods == 0 ? 100 : (numOfCoveredMethods / numOfDefinedMethods) * 100;
}

Graph createGraph(M3 m3, M3 testm3) {
    Graph graph = {};
    set[loc] packages = packages(m3);
    set[loc] testClasses = classes(testm3);
    set[loc] classes = classes(m3);
    set[loc] testInterfaces = interfaces(testm3);
    set[loc] interfaces = interfaces(m3);
    set[loc] testMethods = methods(testm3);
    set[loc] methods = methods(m3);
    
    rel[loc, loc] contains = m3@containment +;
    rel[loc, loc] overrides = m3@methodOverrides +;
    
    
    for (<parent, child> <- contains) {
        if (parent in packages) {
            if (child in classes) {
                graph = graph + <package(parent), definesType(), class(child, child in testClasses)>;
            } else if (child in interfaces) {
                graph = graph + <package(parent), definesType(), interface(child, child in testInterfaces)>;
            }
        } else if (child in methods) {
            if (parent in classes) {
                graph = graph + <class(parent, parent in testClasses), definesMethod(), method(child, child in testMethods)>;
            } else if (parent in interfaces) {
                graph = graph + <interface(parent, parent in testClasses), definesMethod(), method(child, child in testMethods)>;
            }
        }
    }
    
    for (<caller, callee> <- m3@methodInvocation) {
        if (isConstructor(caller)) {
            set[loc] callerClasses = {c | c <- (classes + interfaces), [c, caller] in m3@containment};
            for (callerClass <- callerClasses) { //Should be only one
                if (callerClass in classes) {
                    graph = graph + <class(callerClass, callerClass in testClasses), calls(), method(callee, callee in testMethods)>;
                    graph = graph + {<class(callerClass, callerClass in testClasses), virtualCalls(), method(overridingMethod, overridingMethod in testMethods)> 
                                    | <overridingMethod, overriddenMethod> <- overrides, overriddenMethod == callee};
                } else {
                    graph = graph + <interface(callerClass, callerClass in testInterfaces), calls(), method(callee, callee in testMethods)>;
                    graph = graph + {<interface(callerClass, callerClass in testInterfaces), virtualCalls(), method(overridingMethod, overridingMethod in testMethods)> 
                                    | <overridingMethod, overriddenMethod> <- overrides, overriddenMethod == callee};
                }
            }
        } else {
            graph = graph + <method(caller, caller in testMethods), calls(), method(callee, callee in testMethods)>;
            graph = graph + {<method(caller, caller in testMethods), virtualCalls(), method(overridingMethod, overridingMethod in testMethods)> 
                            | <overridingMethod, overriddenMethod> <- overrides, overriddenMethod == callee};
        }
    }
    
    return graph;
}

set[Node] collectCoveredMethods(Graph graph) {
    set[Node] coveredNodes = {initialNodes | <initialNodes, _, _> <- graph, !initialNodes is package, initialNodes.testCode};
    solve(coveredNodes) {
        coveredNodes = coveredNodes + {newNode | <oldNode, edge, newNode> <- graph, oldNode in coveredNodes, edge is calls || edge is virtualCalls};
        coveredNodes = coveredNodes + {class | <class, edge, containedMethod> <- graph, containedMethod in coveredNodes, edge is definesMethod};
    }
    
    return {coveredNode | coveredNode <- coveredNodes, coveredNode is method};
}

tuple[num, num] getFundamentalMetricsForClass(Graph graph, loc classLoc, set[Node] coveredMethods) {
    return <size({definedMethod | <class, edge, definedMethod> <- graph, edge is definesMethod, class.location == classLoc}),
            size({coveredMethod | <class, edge, coveredMethod> <- graph, edge is definesMethod, class.location == classLoc, coveredMethod in coveredMethods})>;
}