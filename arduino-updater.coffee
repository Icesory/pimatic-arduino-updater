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
      #env.logger.info("Arduion-Updater init")

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
            plugin.disconnect()
            .then(@_flashArduino(pluginName)
            .then(plugin.connect()))
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

      app.post('/arduino-updater/whitelist/:name/:state', (req, res) =>
        new Promise( (resolve, reject) =>
          pluginName = req.params.name
          whiteListState = req.params.state
          if whiteListState
            @config.whitelist.push(pluginName)
            env.logger.debug("#{pluginName} added to whitelist")
          else
            idx = @config.whitelist.indexOf(pluginName)
            if idx not -1
              @config.splice(idx,1)
              env.logger.debug("#{pluginName} removed from whitelist")
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

      plugin = @framework.pluginManager.getPlugin(pluginPropertie.name)
      unless plugin?
        env.logger.error("Plugin #{pluginPropertie.name} does not exist!")
        return false

      env.logger.debug("Plugin #{pluginPropertie.name} is now registered")

      pluginPropertie.whiteListState = false
      if pluginPropertie.name in @config.whitelist
        pluginPropertie.whiteListState = true
      @registeredPlugins.push pluginPropertie
      #env.logger.debug("Registered Plugins: "+@registeredPlugins.join(", "))
      env.logger.debug(@registeredPlugins)
      return true


#    checkAllForUpdate:()=>
#      env.logger.debug("Check for updates")
#      for pluginName in @registeredPlugins
#        @checkForUpdate(pluginName)

#    #This function checks if it neccessary to update an arduino for an plugin
#    checkForUpdate:(pluginName) =>
#      if pluginName not in @registeredPlugins
#        return false
#      plugin = @framework.pluginManager.getPlugin(pluginName)
#      if plugin?
#        plugin.arduinoUpdate(@).catch( (error) =>
#          env.logger.error error
#        )
#      return false

    autoUpdateAllow: (pluginName)=>
      assert typeof pluginName is 'string'
#      env.logger.debug("autoUpdateAllow function")
#      env.logger.debug("whitelist: #{@config.whitelist}")
#      env.logger.debug("pluginName: #{pluginName}")
      if pluginName in @config.whitelist
        return true
      return false

    #Other Plugins can call this function to update their Arduinos when it is necessary.
    #After an update of the Plugin, or for the Inital flash
    #The plugin must  be in the whitelist
    requestArduinoUpdate: (pluginName) =>
      env.logger.debug("ArduinoUpdate request from #{pluginName}")
      pluginPropertie = @_getPluginPropertie(pluginName)
      env.logger.debug(pluginPropertie)
      unless pluginPropertie?
        env.logger.warn("Not registered Plugin: #{pluginName} request a Arduino update")
        return false
      unless pluginName in @config.whitelist
        env.logger.debug("Plugin: #{pluginName} request a Arduino update but isnt whitelisted.")
        return false

      plugin = @framework.pluginManager.getPlugin(pluginName)
      if plugin?
        env.logger.debug("#{pluginName}.disconnect")
        plugin.disconnect().then(()=>
          env.logger.debug("flash")
          @_flashArduino(pluginName).then(()=>
            env.logger.debug("#{pluginName}.connect")
            plugin.connect())).then(()=>
          return true)



#    flashArduino:(pluginName) =>
#      unless pluginName in @config.whitelist
#        return Promise.resolve(false)
#      env.logger.info "Start Arduino flash for #{plugin.config.plugin}"
#      return @_flashArduino(properties)

    _flashArduino: (pluginName) =>
      assert typeof pluginName is "string"
      pluginPropertie = @_getPluginPropertie(pluginName)
      arduino = new Uploader(
        {
          board: pluginPropertie.board,
          port: pluginPropertie.port,
          debug:true
        })
      env.logger.info "Start Arduino flash for #{pluginName}"
      return arduino.flashAsync(pluginPropertie.file)
        .then( () => env.logger.info "Arduino flash done" )
        .catch( (error) => env.logger.error error )

    _getPluginPropertie:(pluginName)=>
      for pluginPropertie in @registeredPlugins
        if pluginPropertie.name is pluginName
          return pluginPropertie


    getSupportedBoards:()=>
      return ["uno", "nano", "mega", "leonardo", "micro", "duemilanove168", "blend-micro",
              "tinyduino", "sf-pro-micro", "qduino", "pinoccio", "imuduino", "feather"]


  ardManager = new ArduinoUpdater()
  return ardManager