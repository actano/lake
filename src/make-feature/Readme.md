# make-feature

    a boilerplate code generator for creating basic library/feature code
    for client/server development as well as views-, test- and style files

    config variables in test/styles are named automaticly after the given feature where neccessary


## Usage

    use

        ./make-feature name [-l][-d]

    where
            name                - feature name

            -l or --library     - feature is not standalone but library feature
                                  instead of index.html a demo.html will be created to demonstrate functionality

            -d or --description - feature/library description, will be written in the component.json

    after running the the generator, switch to the now created folder in /lib and type

           make run

    in case you choosed feature, localhost:8081 in your browser will bring up a "hello world" witch is the
    running servers reponse on the onload request

    in case you choosed library, look at <--library-name-->/build/demo.html

##API

    not available