#########################################
#      Arduino management Plugin        #
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


  class ArduinoManager extends env.plugins.Plugin
    registeredPlugins: []

    init: (app, @framework, @config) =>
      env.logger.info("Arduion-Uploader init")
      #env.logger.info(@framework.pluginManager.pathToPlugin("pimatic-"+@config.plugin))
      #TODO: create a update site for pimatic-mobile-frontend

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
        arduinoProperties = plugin.arduinoUpdate()
        if arduinoProperties?
          console.log arduinoProperties
          if arduinoProperties.update is true
            return @_flashArduino(arduinoProperties, plugin)
      return false

    #Other Plugins can call this function to update their Arduinos when it is necessary.
    #After an update of the Plugin, or for the Inital flash
    #The plugin must not be in the autoUpdateBlacklist
    flashArduino:(properties, plugin) =>
      if plugin.config.plugin in @config.autoUpdateBlacklist
        return false
      return _flashArduino(properties, plugin)


    _flashArduino: (properties, plugin) =>
      arduino = new Uploader(
        {
          board: properties.board,
          port: properties.port
        })
      env.logger.info "Start Arduino flash"
      arduino.flash(properties.file,(error)->
        if(error)
          env.logger.error error
          return false
        else
          env.logger.info "Arduino flash done"
          if plugin?
            plugin.arduinoReady()
          return true
      )


    getSupportedBoards:()=>
      return ["uno", "nano", "mega", "leonardo", "micro", "duemilanove168", "blend-micro",
              "tinyduino", "sf-pro-micro", "qduino", "pinoccio", "imuduino", "feather"]


  ardManager = new ArduinoManager()
  return ardManager