wintersmith-sassify
===================

The Wintersmith Sassify plugin is the most configurable [Node Sass](https://github.com/sass/node-sass) plugin available for [Wintersmith](https://github.com/jnordberg/wintersmith). There are a number of Sass compilation plugins that have been developed throughout the years but Wintersmith Sassify is the first to fully support all configuration options available in Node Sass 3. It's actually a suite of three content plugins, one each for handling Sass files themselves, the outputted CSS, and and outputted CSS source maps. The CSS and/or source map output from each Sass file is added to the Wintersmith content tree rather than being written directly to the disk and served as a static file. This makes it the fastest and most customizable way to integrate Sass into your Wintersmith site.

## Installing

`wintersmith plugin install wintersmith-sassify`

Or if you prefer installing via NPM:

```
npm install [-g] wintersmith-sassify
```

and add `wintersmith-sassify` to your config.json

```
{
  "plugins": [
    "wintersmith-sassify"
  ]
}
```

## Usage

Wintersmith Sassify will run "out of the box" using the default options for Node Sass but to get the most mileage out of Wintersmith Sassify it's recommended that you add your own custom options to your Wintersmith configuration. Assuming you use `config.json` to store your Wintersmith configuration you'd add a `sassify` object and set the configuration options within it.

### Example

```
{
  "plugins": [
    "wintersmith-sassify"
  ],
  "sassify": {
    "outputStyle": "compressed",
    "sourceComments": "false",
    "sourceMap": true
  }
}
```

## Options

As mentioned previously, Wintersmith Sassify supports all the configuration options available in [Node Sass 3](https://github.com/sass/node-sass). This documentation is intended to complement the Node Sass documentation and explain how the Node Sass configuration translates to Wintersmith Sassify. For any option not listed here you may refer solely to the Node Sass documentation.

### file

Type: `String` Default: `dynamic`

Wintersmith Sassify will set this option automatically.

### data

Type: `String` Default: `dynamic`

Wintersmith Sassify will set this option automatically.

### fileGlob

Type: `String` Default: `**/*.s[ac]ss`

The file glob pattern determines what files will be rendered using Wintersmith Sassify.

### includePaths

Type: `Array` Default: `[]`

Node Sass uses the includePaths array to resolve any includes encountered in Sass files. Wintersmith Sassify will automatically add any paths in the Wintersmith contents folder that contain Sass files. Therefore you should only need to set this option if you have Sass includes outside of the contents folder.

### indentedSyntax

Type: `Boolean` Default: `false` Special: automatically set to `true` for `.sass` files

In keeping with Sass convention, this option will automatically be set to true for files with a `.sass` extension. For all other files the option will be set to the value specified in the configuration.

### outFile

Type: `String` Default: `dynamic`

Wintersmith Sassify will set this option automatically.

### sourceMap

Type: `Boolean | String | undefined` Default: `undefined`

When set as a string the string provided will be used as the file path for the source map. While Wintersmith Sassify supports this it is not recommended if your site outputs more than one CSS file as it will break the dynamic mapping between CSS files and their source map.
