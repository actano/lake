WORK IN PROGRESS. THIS DOC IS NOT In SYNC WITH THE ACTUAL CODE (But it illustrates the idea)

lake
====

a very oppinionated make-based build tool for complex and modular web applications that run on NodeJS

Audience
========

Because we build lake especifically for our needs, it turns out to be quite oppinionated about the toolchain.
If you are building a complex web application with NodeJS, Couchbase, Component, CoffeeScript, Jade, Eco, Stylus and Mocha, Chai, PhantomJS for testing, you might be interessted in checking out lake as an alternative to grunt, make or cake.

Installation
============

    cd my_fancy_node_project
    npm install lake --save-dev

You don't want to install it globally. Instead try [this approach](http://stackoverflow.com/a/15157360) and in addition add `alias lake="npm-exec lake"` to yout .bashrc file. Don't forget to `source ~/.bashrc` Now you can use `lake` conveniently from your command line as if it were globally installed.

Usage
=====

    mkdir -p fancy_project/lib/featureA
    cd fancy_projcet
    lake-init
    cd featureA
    lake-add .
    lake
    # builds featureA
    cd ..
    lake
    # builds all features


Motivation
==========
We used to build our application with grunt. That didn't scale to well. Grunt has no internal mechanism of finding out whether a certain file needs to be updated; it uncinditionally runs all steps of a task. If a project reaches a certain complexity, this just takes too much time.

`make` solved this problem a long time ago. Instead of imperatively defining a set of tasks to be run in sequence, you declare a dependency graph along with a set of actions that create target files from a list of source files. `make` than figures out what actions need to run in order to create or update the target files. This approach is way more efficient.

`make` however has a few issues of its own:
* Makefiles are hard to read and write
* it is not trivial to modularize them
* they tend to get pretty big if you try to make them flexible
* shell scriptinhg skills are required

A common pattern to modularize a Makefile is to have a separate Makefile per module and a master Makefile that recusrively uses make to build each module. [This paper](http://aegis.sourceforge.net/auug97.pdf) explains why this pattern is considered harmful and how to correctly modularize the build process by using a single make session and a file per module that is *included* into a single Makefile.

Because target names need to be unique within the single Makefile and modules tend to have a common layout, clashing target names are a problem.

To solve the above problems, we decided to generate our Makefile and the files it includes as part of the build process. This is what `lake` does prior to spawing a `make` session.

Files
=====

.lake directory
---------------
Stores private data like generated Makefile.mk files etc. Just like the .git direcotey, you normally have no neeed to look into this.

.lake/features
--------------
Stores a list of locations of Manifest files that contribute targets to the generated Makefile.
`lake-add` adds a location to the list.

.lake/config
--------------
A JSON file that contains values, that you use in every rule.
The key **ruleCollection** contains an array with paths to your rules, relative to the *.lake* directory.


Manifest.coffee
--------
This file lists various source files that make up different aspects of a particular feature.

These aspects include:
* server-side code (coffee)
* client-side code (coffee)
* client-side templates (jade)
* server-side and client-side unit and integration tests (coffee, mocha, chai, phantomjs)
* CSS styles (stylus)
* client-side dependencies (components)
* couchbase view code (js)

TODO: Manifest format

local targets
=============
To solve the clashing target name problem mentioned above, we use a module's directory as a namespace for its targets.
In the generated Makefile `lake` prepends target names with the directory of the module they originate from. That is, it uses the relative path from a Manifest to the .lake directory as a prefix for the targets generated from that Manifest.

Conversely, `lake` prefixes the name of a target given on the command line with the current working directory relative to the the location of .lake (i.e. project's root).

The net effect is that you can build, test and demo the module you are currently working on in isolation.

Example
-------

directory structure

    fancy_project
        .lake
            stuff you can ignore
        lib
            featureA
                Manifest.coffee
            featureB
                Manifest.cooffee

shell session

    fancy_project$ lake test
    # Builds and runs unit-tests for the whole project

    fancy_project$ cd lib/featureA
    fancy_project/lib/featureA$ lake test
    # Builds and runs unit-tests for feature A only

Name
====
We used to call it local-make, then lmake and now it is called `lake`. It is not related to the LUA build tool.
