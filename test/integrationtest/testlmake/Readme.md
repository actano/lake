
# testlmake

  This module tests lake and its dependency feature

  The integration test modify some sources, which are dependencies of testlmake.
  After every change the the browser test will be adjust,
  then calling lake with the 'client_target' which recompiles the sources and run the new test.