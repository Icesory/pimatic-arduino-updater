module.exports = {
  title: "pimatic-arduino-updater"
  type: "object"
  properties:
    blacklist:
      description: "Plugins, which are not allowed to register. To blacklist Pimatic-Homeduino you must insert \"homeduino\"."
      type: "array"
      format: "table"
      default: []
      items:
        type: "string"
    autoUpdateBlacklist:
      description: "Plugins, which are not allowed to automatically update their Arduinos. "
      type: "array"
      format: "table"
      default: []
      items:
        type: "string"
}