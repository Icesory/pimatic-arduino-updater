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


  class ArduinoManager extends env.plugins.Plugin
  ardManager = new ArduinoManager

    init: (app, @framework, @config) =>
      env.logger.info("Hello World")

  # and return it to the framework.
  return ardManager