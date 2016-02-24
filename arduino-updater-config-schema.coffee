module.exports = {
  title: "pimatic-arduino-updater"
  type: "object"
  properties:
    whitelist:
      description: "Plugins, which are allowed to automatically update their Arduinos."
      type: "array"
      format: "table"
      default: []
      items:
        type: "string"
    alternativeHexfiles:
      description: "Alternative hexfile paths."
      type: "object"
      default: {}

}