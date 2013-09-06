module.exports = nconf = require("nconf")

# 1. put environment variables into conf 
#    (__ is the separator, e.g. 'export app__port=8081')
# 2. command line arguments
nconf.env('__').argv()

# 3. Values in `config.json`
#nconf.file "global-config-file.json"

# 4. Any default values
nconf.defaults
    app:
        port: 8081
        test_coverage_port: 3000

    couchbase:
        memcached_port: 11211
        couchbase_port: 8092
        couchbase_protocol: 'http'
        couchbase_host: 'localhost'
        couchbase_bucket: 'default'

    couchbaseImportBucket:
        memcached_port: 11212


