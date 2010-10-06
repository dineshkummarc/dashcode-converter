# Dashcode Converter #

This tool converts Apple Dashcode projects into NIBs for use with the [Coherent Javascript framework](http://github.com/jeffwatkins/coherent/).

## Installation ##

Like all Ruby Gems, installation is really simple:

    $ gem install dashcode-converter

## Usage ##

You can pass `dashcode-converter` either the path to a Dashcode project file (ending in .dcproj) or a folder that contains a Dashcode project file. For example:

    $ dashcode-converter ~/Projects/RssReader.dcproj
    
This will create a Coherent NIB package in the `out` folder with the same name as the project. The NIB package will contain an HTML file, CSS file, copies of any images used by the project's HTML and CSS files, a controller class file, and a NIB definition.

