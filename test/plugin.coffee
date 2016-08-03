assert = require 'assert'
async = require 'async'
vows = require 'vows'
wintersmith = require 'wintersmith'

suite = vows.describe 'Plugin'

suite.addBatch

  'wintersmith environment':

    topic: -> 
      wintersmith './test/example/config.json'

    'loaded ok': (env) ->
      assert.instanceOf env, wintersmith.Environment

    'contents':

      topic: (env) -> 
        env.load (err, result) =>
          @callback err, result, env

      'loaded ok': (err, result, env) ->
        assert.isNull err
        assert.instanceOf result.contents, wintersmith.ContentTree

      'has plugin instances': (err, result, env) ->
        assert.instanceOf result.contents['someScss.scss'], env.plugins.Sass
        assert.instanceOf result.contents['someSass.sass'], env.plugins.Sass
        assert.instanceOf result.contents['someScss.css'].sassFile, env.plugins.Sass
        assert.instanceOf result.contents['someSass.css'].sassFile, env.plugins.Sass
        assert.instanceOf result.contents['someScss.css.map'].sassFile, env.plugins.Sass
        assert.instanceOf result.contents['someSass.css.map'].sassFile, env.plugins.Sass

      'views':

        topic: (result, env) ->
          views = []

          # Render each view and save the plugin instance and rendered content
          async.each result.contents, (plugin, callback) ->
            plugin.getView().call plugin, env, result.locals, result.contents, result.templates, (err, output) ->
              if err
                callback err
              else
                views.push
                  plugin: plugin
                  content: do output.toString
                callback null

          , (err) =>
            @callback err, views, env

          undefined

        'rendered ok': (err, views, env) ->
          assert.isNull err

        'have expected content': (err, views, env) ->
          correct = true

          for view in views
            filename = do view.plugin.getFilename
            extension = filename.substr filename.lastIndexOf '.'

            # Source maps are JSON so we parse them and check their properties.
            if extension is '.map'
              map = JSON.parse view.content
              correct = false unless map.file is filename.replace(extension, '') and map.sources.length is 1
            # In all other cases check for content from the example.
            else
              correct = false unless /Wintersmith Node Sass 3/.test(view.content) and /is working properly\./.test(view.content)

            break unless correct

          assert.isTrue correct

suite.export module
