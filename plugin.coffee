### Wintersmith Sassify Plugin ###

# Set default options for Node Sass
# https://github.com/sass/node-sass
defaults =
  fileGlob: '**/*.s[ac]ss'
  includePaths: []
  indentedSyntax: false
  indentType: 'space'
  indentWidth: 2
  linefeed: 'lf'
  omitSourceMapUrl: false
  outputStyle: 'nested'
  precision: 5
  sourceComments: false
  sourceMap: undefined
  sourceMapContents: false
  sourceMapEmbed: false
  sourceMapRoot: undefined

# Require dependencies
fs       = require 'fs'
nodeSass = require 'node-sass'

# The extend in Wintersmith env.utils only accepts two arguments at a time so...
extend = (base = {}, objects...) ->
  for i, object of objects
    for prop, val of object
      base[prop] = val
  base

# This config var will become a shorthand for env.config['sassify']
config = {}

module.exports = (env, callback) ->
  # The final environment configuration is derived from extending the current
  # plugin configuration from the Wintersmith environment with the plugin
  # defaults. At render time the configuration passed to Node Sass will be
  # derived by extending the environment configuration with the plugin
  # instance's configuration property.
  env.config['sassify'] = config = extend {}, defaults, env.config['sassify']


  # The Sass plugin manages the Sass file itself. If the Sass file is to output
  # CSS or a source map that is handled by the other respective plugins.
  class Sass extends env.ContentPlugin

    # Note that all files with a .sass extension will be rendered using indented
    # syntax regardless of the configuration setting.
    constructor: (@filePath, fileContents) ->
      @config =
        file: @filePath.full
        data: do fileContents.toString
        indentedSyntax: if /\.sass$/.test(@filePath.relative) then true else config.indentedSyntax

      unless do @isPartial
        @css = new CSS @
        extend @config,
          outFile: do @css.getFilename

      if do @hasSourceMap
        @sourceMap = new SourceMap @

    getConfig: ->
      extend {}, config, @config

    getFilename: ->
      @filePath.relative

    getView: -> (env, locals, contents, templates, callback) ->
      callback null, Buffer.from @config.data

    hasSourceMap: ->
      sassConfig = do @getConfig
      not do @isPartial and sassConfig.sourceMap and not sassConfig.sourceMapEmbed

    isPartial: ->
      /^_/.test @filePath.name

    # Any CSS or source maps derived from this file will use this method to
    # render their output. Note that the rendered Sass file is cached.
    render: (output, callback) ->
      return callback null, @rendered[output] if @rendered
      nodeSass.render do @getConfig, (err, result) =>
        return callback err if err or not result?[output]
        callback null, (@rendered = result)[output]


  # The CSS plugin manages any CSS that is to be output by a Sass file.
  class CSS extends env.ContentPlugin

    constructor: (@sassFile) ->

    getFilename: ->
      @sassFile.filePath.relative.replace /\.s[ac]ss$/i, '.css'

    getUrl: ->
      super env.config.baseUrl

    getView: -> (env, locals, contents, templates, callback) ->
      @sassFile.render 'css', callback


  # The SourceMap plugin manages any source maps to be output by a Sass file.
  class SourceMap extends env.ContentPlugin

    constructor: (@sassFile) ->
      sourceMap = @sassFile.getConfig().sourceMap
      @customName = if sourceMap and sourceMap.length then sourceMap else false

    getFilename: ->
      @customName or @sassFile.filePath.relative.replace /\.s[ac]ss$/i, '.css.map'

    getUrl: ->
      @customName or super env.config.baseUrl

    getView: -> (env, locals, contents, templates, callback) ->
      @sassFile.render 'map', (err, result) =>
        return callback err if err or not result
        @resolveSourcePaths result, callback

    # Source paths from Node Sass will be file paths rather than URLs so they
    # need to be resolved to relative URLs.
    resolveSourcePaths: (result, callback) ->
      contentsPath = new RegExp "\"([\.\/]*)?#{env.config.contents.substr 2}\/", 'g'
      map = result.toString().replace contentsPath, '"$1'
      callback null, Buffer.from map


  # This content tree will contain the "virtual" CSS and source maps generated
  # by our Sass files and registered as a generator with Wintermsith. This
  # "virtual" content tree will be merged with Wintermsith with the "real"
  # content tree that is generated from the Wintersmith contents directory.
  contentTree = new class ContentTree

    constructor: ->
      @tree = {}

    add: (content) ->
      pointer = @tree
      components = content.getUrl().replace(/^\//, '').split '/'

      for component, index in components
        if index < (components.length - 1)
          pointer[component] ?= {}
          pointer = pointer[component]
        else
          pointer[component] = content

    get: (contents, callback) =>
      callback null, @tree


  # When scanning the file tree for Sass files a Sass plugin instance will be
  # constructed first and then, if necessary, the CSS and/or SourceMap instances
  # will be added to the plugin's content tree.
  Sass.fromFile = (filePath, callback) ->
    filePath.name = /[^\\\/\.]*\.s[ac]ss$/i.exec(filePath.relative)[0]

    if config.includePaths.indexOf(folder = filePath.full.replace filePath.name, '') < 0
      config.includePaths.push folder

    fs.readFile filePath.full, (err, fileContents) ->
      return callback err if err

      sass = new Sass filePath, fileContents

      unless do sass.isPartial
        contentTree.add sass.css
        if do sass.hasSourceMap
          contentTree.add sass.sourceMap

      callback null, sass


  # The glob pattern used to register the plugin is configurable and defaults
  # to all .scss and .sass files.
  env.registerContentPlugin 'styles', config.fileGlob, Sass
  env.registerGenerator 'styles', contentTree.get


  do callback
