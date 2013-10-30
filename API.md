# RuleBook API - status quo

* [creata rulebook](#create_rulebook)
* [adding rules](#adding_rules)
* [rule references](#rule_references)

<a name="create_rulebook" />
## create a new rulebook
new RuleBook()

<a name="adding_rules" />
## adding rules

<a name="addRule" />
### addRule (id, tags, func) ->
add a new rule to the rulebook

* id - string - id of the rule
* tags - array of strings - rule will be tagged with these values
* func - function - factory which return an object with three properties:
    * targets - string/array of strings - make targets
    * dependencies - string/array of strings - make targets
    * actions - string/array of strings - make targets
* returns the created rule (doesn't resolve the factory at this time)

within the function, you can access to other rules and their targets, dependencies via **[getRuleById()](#getRuleById)** or **[getRulesByTag()](#getRulesByTag)**

the factory will be resolved when calling function which are listed under **rule reference access**

<a name="addToGlobalTarget" />
### addToGlobalTarget (targetName, rule) 
add a rule to a global target (accumulate targets for each feature and use them as dependency in a global target)

* targetName - string - name of the target, which will be accumulated in the global Makefile
* rule - rule - reference to a rule which was created via **[addRule()](#addRule)**

<a name="rule_references" />
## rule reference access
 
<a name="getRuleById" />
### getRuleById(id, [default=null])
return the rule for the given id
* id - string - id of the rule
* defaultValue - mixed - return value of no rules is found for the given id

<a name="getRulesByTag" />
### getRulesByTag(id, [arrayMode=true])
returns rules which have the given tag

* id - string - id of the rule which is returned
* arrayMode - boolean - if false, the result is  a key-value object, where the key is the 

if no rules matched, [] or {} will be returned

<a name="getRules" />
### getRules([idArray])
* idArray - array of strings - if null return all rules, otherwise rules for the given IDs

call for given rules **[_getOrResolve()](#_getOrResolve)**

<a name="resolveAllFactories" />
### resolveAllFactories()
call **[_getOrResolve()](#_getOrResolve)** for all rules

<a name="_getOrResolve" />
### _getOrResolve(id, defaultValue)
resolve a rule with the given id, or return the already resolved rule. Dependencies (via **[getRuleById()](#getRuleById)** or **[getRulesByTag()](#getRulesByTag)**) are resolved automaticly, you don't need to pay attention in which order the rules are created via **[addRule()](#addRule)**. Circular dependencies are not allowed and produce an exception.

* id - string - id of the rule
* defaultValue - mixed - return value of no rules is found for the given id

## problems

**[getRuleById()](#getRuleById)** and **[getRulesByTag()** can be called within the factory regardless to the order (of adding the rules).

But if **[getRuleById()](#getRuleById)** and **[getRulesByTag()** are called beyond the factory or an scope above, the order matters.

Should this be allowed?
Or extending the API with a **close()** function, which should be called before using **[getRuleById()](#getRuleById)** and **[getRulesByTag()**. After **closed()** was called no rule can be added anymore. 
