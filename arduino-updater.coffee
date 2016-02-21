#########################################
#        Arduino update Plugin          #
# This Plugin allows Pimatic to upload  #
# new Programms to our arduinos.        #
#########################################
module.exports = (env) ->

  # ###require modules included in pimatic
  # To require modules that are included in pimatic use `env.require`. For available packages take
  # a look at the dependencies section in pimatics package.json

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  Uploader = require 'avrgirl-arduino'
  Promise.promisifyAll(Uploader.prototype)

  class ArduinoUpdater extends env.plugins.Plugin
    registeredPlugins: []

    init: (app, @framework, @config) =>
      env.logger.info("Arduion-Updater init")

      @framework.on "after init", =>
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', "pimatic-arduino-updater/app/arduino-updater.coffee"
          mobileFrontend.registerAssetFile 'html', "pimatic-arduino-updater/app/arduino-updater.jade"
          mobileFrontend.registerAssetFile 'css', "pimatic-arduino-updater/app/arduino-updater.css"
        else
          env.logger.warn "Arduion Updater could not find mobile-frontend. Didn't add updater page."

      app.get('/arduino-updater/registerd-plugins', (req, res) =>
        res.send(@registeredPlugins.map( (name) -> {name: name }))
      )

      app.post('/arduino-updater/flash/:name', (req, res) =>
        new Promise( (resolve, reject) =>
          pluginName = req.params.name
          plugin = @framework.pluginManager.getPlugin(pluginName)
          if plugin?
            plugin.arduinoUpdate(@)
              .then(resolve, reject)
          else
            reject(new Error("Could not find plugin"))
        ).then( () =>
          res.send({
            success: true,
            message: "Update successful"
          })
        ).catch( (error) =>
          res.send(500, {
            success: false,
            message: error.message}
          )
        )
      )

    registerPlugin: (pluginName) =>
      assert typeof pluginName is 'string'
      if pluginName in @config.blacklist
        return false
      env.logger.info("Plugin #{pluginName} is now registered")
      @registeredPlugins.push pluginName
      env.logger.info("Registered Plugins: "+@registeredPlugins.join(", "))
      return true
      #@checkAllForUpdate()

    checkAllForUpdate:()=>
      env.logger.info("Check for updates")
      for pluginName in @registeredPlugins
        @checkForUpdate(pluginName)

    #This function checks if it neccessary to update an arduino for an plugin
    checkForUpdate:(pluginName) =>
      if pluginName not in @registeredPlugins
        return false
      plugin = @framework.pluginManager.getPlugin(pluginName)
      if plugin?
        plugin.arduinoUpdate(@).catch( (error) =>
          env.logger.error error
        )
      return false

    #Other Plugins can call this function to update their Arduinos when it is necessary.
    #After an update of the Plugin, or for the Inital flash
    #The plugin must not be in the autoUpdateBlacklist
    flashArduino:(properties, plugin) =>
      if plugin.config.plugin in @config.autoUpdateBlacklist
        return Promise.resolve()
      return @_flashArduino(properties, plugin)


    _flashArduino: (properties, plugin) =>
      arduino = new Uploader(
        {
          board: properties.board,
          port: properties.port,
          debug:false
        })
      env.logger.info "Start Arduino flash"


      return arduino.flashAsync(properties.file)
        .then( () => env.logger.info "Arduino flash done" )
        .catch( (error) => env.logger.error error )


    getSupportedBoards:()=>
      return ["uno", "nano", "mega", "leonardo", "micro", "duemilanove168", "blend-micro",
              "tinyduino", "sf-pro-micro", "qduino", "pinoccio", "imuduino", "feather"]


  ardManager = new ArduinoUpdater()
  return ardManager