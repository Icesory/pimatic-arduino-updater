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
  fs = require('fs')
  Promise.promisifyAll(Uploader.prototype)

  class ArduinoUpdater extends env.plugins.Plugin
    registeredPlugins: []
    uploaders=["uno", "nano", "mega", "leonardo", "micro", "duemilanove168", "blend-micro",
              "tinyduino", "sf-pro-micro", "qduino", "pinoccio", "imuduino", "feather"]

    init: (app, @framework, @config) =>
      @framework.on "after init", =>
        mobileFrontend = @framework.pluginManager.getPlugin 'mobile-frontend'
        if mobileFrontend?
          mobileFrontend.registerAssetFile 'js', "pimatic-arduino-updater/app/arduino-updater.coffee"
          mobileFrontend.registerAssetFile 'html', "pimatic-arduino-updater/app/arduino-updater.jade"
          mobileFrontend.registerAssetFile 'css', "pimatic-arduino-updater/app/arduino-updater.css"
        else
          @_debugOutput("Arduino Updater could not find mobile-frontend. Didn't add updater page.")

      app.get('/arduino-updater/registerd-plugins', (req, res) =>
        res.send(@registeredPlugins)
      )

      app.post('/arduino-updater/flash/:name', (req, res) =>
        new Promise( (resolve, reject) =>
          pluginName = req.params.name
          plugin = @framework.pluginManager.getPlugin(pluginName)
          pluginPropertie = @_getPluginPropertie(pluginName)
          if pluginPropertie.flashInprogress
            resolve()
          if plugin?
            plugin.disconnect()
            .then( => @_flashArduino(pluginName) )
            .then( => plugin.connect() )
          else
            reject(new Error("Could not find plugin"))
        )
        res.send({
          success: true,
          #message: "Flash startet"
        })
#        .then( () =>
#          res.send({
#            success: true,
#            message: "Update successful"
#          })
#        )
#        .catch( (error) =>
#          res.send(500, {
#            success: false,
#            message: error.message}
#          )
#        )
      )

      app.post('/arduino-updater/whitelist/:name/:state', (req, res) =>
        new Promise( (resolve, reject) =>
          pluginName = req.params.name
          whiteListState = req.params.state
          pluginPropertie = @_getPluginPropertie(pluginName)
          if whiteListState is 'true'
            unless pluginName in @config.whitelist
              @config.whitelist.push(pluginName)
            pluginPropertie.whiteListState=true
            @_debugOutput("#{pluginName} added to whitelist")
          else
            idx = @config.whitelist.indexOf(pluginName)
            if idx >= 0
              @config.whitelist.splice(idx,1)
              pluginPropertie.whiteListState=false
              @_debugOutput("#{pluginName} removed from whitelist")
          resolve()
        ).then( () =>
          res.send({
            success: true,
          })
        ).catch( (error) =>
          res.send(500, {
            success: false,
            message: error.message}
          )
        )
      )

    registerPlugin: (pluginPropertie) =>
      assert typeof pluginPropertie is "object"
      assert typeof pluginPropertie.name is "string"
      assert typeof pluginPropertie.port is "string"
      assert typeof pluginPropertie.board is "string"
      assert typeof pluginPropertie.file is "string"
      assert pluginPropertie.uploader in uploaders

      plugin = @framework.pluginManager.getPlugin(pluginPropertie.name)
      unless plugin?
        env.logger.error("Plugin #{pluginPropertie.name} does not exist!")
        return false

      @_debugOutput("Plugin #{pluginPropertie.name} is now registered")

      pluginPropertie.flashInprogress = false
      pluginPropertie.whiteListState = false
      pluginPropertie.updateRequired = false
      if pluginPropertie.name in @config.whitelist
        pluginPropertie.whiteListState = true

      if @config.alternativeHexfiles[pluginPropertie.name]?
        if @_checkFileExist(@config.alternativeHexfiles[pluginPropertie.name])
          @_debugOutput("Override hexfile path for Plugin #{pluginPropertie.name}")
          pluginPropertie.path=@config.alternativeHexfiles[pluginPropertie.name]
        else
          env.logger.error("Alternative hexfile:#{@config.alternativeHexfiles[pluginPropertie.name]}"+
                           " for Plugin:#{pluginPropertie.name} dosn´t exist.")

      @registeredPlugins.push pluginPropertie
      return true

    autoUpdateAllow: (pluginName)=>
      assert typeof pluginName is 'string'
      if pluginName in @config.whitelist
        return true
      return false

    #Other Plugins can call this function to update their Arduinos when it is necessary.
    #After an update of the Plugin, or for the Inital flash
    #The plugin must  be in the whitelist
    requestArduinoUpdate: (pluginName) =>
      @_debugOutput("ArduinoUpdate request from #{pluginName}")
      pluginPropertie = @_getPluginPropertie(pluginName)
      env.logger.debug(pluginPropertie)
      unless pluginPropertie?
        env.logger.warn("Not registered Plugin: #{pluginName} request a Arduino update")
        return Promise.resolve(false)
      unless pluginName in @config.whitelist
        @_debugOutput("Plugin: #{pluginName} request a Arduino update but isnt whitelisted.")
        pluginPropertie.updateRequired = true #For GUI
        env.logger.debug(@registeredPlugins)
        return Promise.resolve(false)
      plugin = @framework.pluginManager.getPlugin(pluginName)
      if plugin?
        @_debugOutput("#{pluginName}.disconnect")
        plugin.disconnect()
        .then( () =>
          @_debugOutput("flash") #This line is not executed
          return @_flashArduino(pluginName).catch( (error) =>
            env.logger.error("Error flashing arduino: #{error.message}")
            eng.logger.debug(error.stack)
          )
        ).then( ()=>
          @_debugOutput("#{pluginName}.connect") #This line is not executed
          return plugin.connect()
        ).then(( ) =>
          return true
        )
      else
        return Promise.resolve(false)

    _flashArduino: (pluginName) =>
      assert typeof pluginName is "string"
      pluginPropertie = @_getPluginPropertie(pluginName)
      if pluginPropertie.flashInprogress is true
        return Promise.reject()
      pluginPropertie.flashInprogress = true
      arduino = new Uploader(
        {
          board: pluginPropertie.uploader,
          port: pluginPropertie.port,
          debug: @config.debug
        })
      env.logger.info "Start Arduino flash for #{pluginName}"
      return arduino.flashAsync(pluginPropertie.file)
        .then( () =>
          env.logger.info "Arduino flash done" )
        .catch( (error) => env.logger.error error )
        .finally( ()=>
          pluginPropertie.flashInprogress = false
        )

    _getPluginPropertie:(pluginName)=>
      for pluginPropertie in @registeredPlugins
        if pluginPropertie.name is pluginName
          return pluginPropertie

    _checkFileExist:(path)=>
      try
        return fs.statSync(path).isFile()
      catch e
        return false

    _debugOutput:(string)=>
      if @config.debug
        env.logger.debug(string)

    getSupportedBoards:()=>
      return uploaders


  ardManager = new ArduinoUpdater()
  return ardManager