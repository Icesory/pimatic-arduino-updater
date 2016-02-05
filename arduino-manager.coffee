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
  uploader = require 'avrgirl-arduino'
  serialport = require 'serialport'

  #neccessary eventually for avr-gcc
  #spawn = require("child_process").spawn

  serialPorts = {}
  availablePorts = {}
  arduinoProperties = {}

  class ArduinoManager extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      env.logger.info("Hello World")

  ardManager = new ArduinoManager()

  getPort: (pluginName) ->
    serialPorts[pluginName] = serialport.SerialPort
    availablePorts[pluginName] = true;
    return serialPorts[pluginName]

  portAvailable: (pluginName) ->
    return availablePorts[pluginName]
  # and return it to the framework.

  setArduino: (pluginName, arduino)->
    #arduino must be an obejct, which contains the Type and the Port
    ###
    {
      "type": "UNO"
      "port": "/dev/ttyUSB0"
    }
    ###
    arduinoProperties[pluginName] = arduino

  return ardManager