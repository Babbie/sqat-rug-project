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
A whole bunch, execute getNonCoveredMethods(jpacmanM3(), jpacmanTestM3()); to find out
- how do your results compare to the jpacman results in the paper? Has jpacman improved?
Both our static coverage and Clover's coverage have gotten lower.
Static went from 84.53 to 72.84 and Clover went from 9.61 to 74.8.
- use a third-party coverage tool (e.g. Clover) to compare your results to (explain differences)
Our static analysis resulted in a system-wide coverage of 72.84%, while clover reports 74,8% coverage.
This seems correct, as our coverage tool does not look what parts of code within methods are covered and simply
assumes it's all covered if the method is called, but Clover seems to register methods that aren't actually covered
(see Inky#nextMove());


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

set[loc] getNonCoveredMethods(M3 m3, M3 testm3) {
    Graph graph = createGraph(m3, testm3);
    set[Node] coveredMethods = collectCoveredMethods(graph);
    set[loc] nonCoveredMethods = (methods(m3) - methods(testm3)) - {coveredMethod.location | coveredMethod <- coveredMethods};

    return nonCoveredMethods;
}

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
    
    // divide by 0 means it's technically all covered, since there is nothing
    return numOfDefinedMethods == 0 ? 100 : (numOfCoveredMethods / numOfDefinedMethods) * 100;
}

Graph createGraph(M3 m3, M3 testm3) {
    Graph graph = {};
    // get data from m3s
    set[loc] packages = packages(m3);
    set[loc] testClasses = classes(testm3);
    set[loc] classes = classes(m3);
    set[loc] testInterfaces = interfaces(testm3);
    set[loc] interfaces = interfaces(m3);
    set[loc] testMethods = methods(testm3);
    set[loc] methods = methods(m3);
    
    // transitive closures
    rel[loc, loc] contains = m3@containment +;
    rel[loc, loc] overrides = m3@methodOverrides +;
    
    for (<parent, child> <- contains) {
        if (parent in packages) {
            if (child in classes) {
                // package definesType class
                graph = graph + <package(parent), definesType(), class(child, child in testClasses)>;
            } else if (child in interfaces) {
                // package definesType interface
                graph = graph + <package(parent), definesType(), interface(child, child in testInterfaces)>;
            }
        } else if (child in methods) {
            if (parent in classes) {
                // class definesMethod method
                graph = graph + <class(parent, parent in testClasses), definesMethod(), method(child, child in testMethods)>;
            } else if (parent in interfaces) {
                // interface definesMethod method
                graph = graph + <interface(parent, parent in testClasses), definesMethod(), method(child, child in testMethods)>;
            }
        }
    }
    
    for (<caller, callee> <- m3@methodInvocation) {
        if (isConstructor(caller)) {
            set[loc] callerClasses = {c | c <- (classes + interfaces), [c, caller] in m3@containment};
            for (callerClass <- callerClasses) { //Should be only one
                if (callerClass in classes) {
                    // constructor calls method -> class calls method
                    graph = graph + <class(callerClass, callerClass in testClasses), calls(), method(callee, callee in testMethods)>;
                    // class calls all methods that override method
                    graph = graph + {<class(callerClass, callerClass in testClasses), virtualCalls(), method(overridingMethod, overridingMethod in testMethods)> 
                                    | <overridingMethod, overriddenMethod> <- overrides, overriddenMethod == callee};
                } else {
                    // constructor calls method -> interface calls method
                    graph = graph + <interface(callerClass, callerClass in testInterfaces), calls(), method(callee, callee in testMethods)>;
                    // interface calls all methods that override method
                    graph = graph + {<interface(callerClass, callerClass in testInterfaces), virtualCalls(), method(overridingMethod, overridingMethod in testMethods)> 
                                    | <overridingMethod, overriddenMethod> <- overrides, overriddenMethod == callee};
                }
            }
        } else {
            // method calls method
            graph = graph + <method(caller, caller in testMethods), calls(), method(callee, callee in testMethods)>;
            // method calls all methods that override method
            graph = graph + {<method(caller, caller in testMethods), virtualCalls(), method(overridingMethod, overridingMethod in testMethods)> 
                            | <overridingMethod, overriddenMethod> <- overrides, overriddenMethod == callee};
        }
    }
    
    return graph;
}

set[Node] collectCoveredMethods(Graph graph) {
    // initialize coveredNodes to all test methods via package
    set[Node] coveredNodes = {initialNode | <packageNode, edge, initialNode> <- graph, packageNode is package, edge is definesType, initialNode.testCode};
    coveredNodes = {methodNode | <classNode, edge, methodNode> <- graph, edge is definesMethod, classNode in coveredNodes};
    solve(coveredNodes) {
        // add all nodes reachable through calls or virtualCalls
        coveredNodes = coveredNodes + {newNode | <oldNode, edge, newNode> <- graph, oldNode in coveredNodes, edge is calls || edge is virtualCalls};
        // add all classes/interfaces whose methods are covered
        coveredNodes = coveredNodes + {class | <class, edge, containedMethod> <- graph, containedMethod in coveredNodes, edge is definesMethod};
    }
    
    // return only methods, not classes or interfaces
    return {coveredNode | coveredNode <- coveredNodes, coveredNode is method};
}

tuple[num, num] getFundamentalMetricsForClass(Graph graph, loc classLoc, set[Node] coveredMethods) {
    return <size({definedMethod | <class, edge, definedMethod> <- graph, edge is definesMethod, class.location == classLoc}),
            size({coveredMethod | <class, edge, coveredMethod> <- graph, edge is definesMethod, class.location == classLoc, coveredMethod in coveredMethods})>;
}