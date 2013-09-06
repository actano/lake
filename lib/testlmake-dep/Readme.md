
# helloworld

  Copy this directory to get started quickly. You get

  + Manifest.coffee - the feature's manifest. It provides information (like name and dependencies) to the build process
  + client.coffee - client code (runs in the browser)
  + server.coffee - server code (runs in NodeJS)
  + a bunch of jade templates in the views/ folder
    + demo.jade / index.jade - (depends if it's a library or not)
  + a test/ folder that holds all your great tests
    + unit tests for the server-side code *-test.coffee
    + integration tests checking both client and server side code (and potentially database and other parts of the stack as well) *-itest.coffee
    + phantomJS-based tests *-phantomtest.coffee
    + tests that run in all browsers (including phantom) *-browsertest.coffee
    + test.jade - test runner boilerplate for browser tests
  + a styles/ folder that holds all styles written in Stylus
  + this helpful markdown file as boilerplate for your own documentation


## TODO
  + put the feature's name into component.json
  + replace all of this text with a description of what the feature/component does
  + document the API in the next section

## API

