tc = pimatic.tryCatch
linkAdded = no
$(document).on( "pagebeforecreate", (event) ->
  if linkAdded then return
  console.log("adding")
  li = $ """
    <li data-theme="f">
      <a
        href="\#arduino-updater-page"
        data-transition="slidefade"
        class="ui-btn ui-btn-f ui-btn-icon-right ui-icon-carat-r arduino-updater-plugin"
      >
        Arduino Updater
      </a>
    </li>
  """
  menu = $('#nav-panel ul li:last')
  console.log menu
  menu.before(li)
  linkAdded = yes
)

$(document).on("pagecreate", '#arduino-updater-page', tc (event) ->

  class ArduinoUpdaterViewModel

    @mapping = {
      $default: 'ignore'
      registeredPlugins:
        $key: 'name'
        $itemOptions:
          $handler: 'copy'
    }


    constructor: ->

      @updateFromJs([])

      @updateListView = ko.computed( =>
        @registeredPlugins()
        pimatic.try -> $('#registered-plugins-list').listview('refresh')
      )

      # pimatic.socket.on('messageLogged', tc (entry) =>
      #   @messages.unshift({
      #     tags: entry.meta.tags
      #     level: entry.level
      #     text: entry.msg
      #     time: entry.meta.timestamp
      #   })
      # )

    updateFromJs: (data) ->
      ko.mapper.fromJS({registeredPlugins: data}, ArduinoUpdaterViewModel.mapping, this)

    loadRegisteredPlugins: ->
      $.ajax({
        url: '/arduino-updater/registerd-plugins',
        type: 'GET',
        global: false
      }).done( (plugins) =>
        @updateFromJs(plugins)
      )

    onUpdateKlicked: (plugin) =>
      $.ajax({
        url: "/arduino-updater/flash/#{plugin.name}",
        type: 'POST',
        global: true
      }).done(ajaxShowToast)
      .fail(ajaxAlertFail)

    onCheckboxChange: ()=>
      console.log "Checkbox klicked"
      checkboxState = true
      $.ajax({
        url: "/arduino-updater/whitelist/#{plugin.name}/#{checkboxState}",
        type: 'POST',
        global: true
      }).done(ajaxShowToast)
      .fail(ajaxAlertFail)

  try
    pimatic.pages.arduinoUpdater = arduinoUpdaterPage = new ArduinoUpdaterViewModel()
    ko.applyBindings(arduinoUpdaterPage, $('#arduino-updater-page')[0])
  catch e
    TraceKit.report(e)
  return
)

$(document).on("pagebeforeshow", '#arduino-updater-page', tc (event) ->
  try
    arduinoUpdaterPage = pimatic.pages.arduinoUpdater
    arduinoUpdaterPage.loadRegisteredPlugins()
  catch e
    TraceKit.report(e)
)
