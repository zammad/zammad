#s#= require json2
#= require ./lib/jquery-1.8.1.min.js
#= require ./lib/ui/jquery-ui-1.8.23.custom.min.js

#= require ./lib/spine/spine.js
#= require ./lib/spine/ajax.js
#= require ./lib/spine/route.js

#= require ./lib/bootstrap-dropdown.js
#= require ./lib/bootstrap-tooltip.js
#= require ./lib/bootstrap-popover.js
#= require ./lib/bootstrap-modal.js
#= require ./lib/bootstrap-tab.js
#= require ./lib/bootstrap-transition.js

#= require ./lib/underscore-1.3.3.js
#= require ./lib/ba-linkify.js
#= require ./lib/jquery.tagsinput.js
#= require ./lib/jquery.noty.js
#= require ./lib/waypoints.js
#= require ./lib/fileuploader.js
#= require ./lib/jquery.elastic.source.js

#not_used= require_tree ./lib
#= require_self
#= require ./lib/ajax.js.coffee
#= require ./lib/websocket.js.coffee
#= require ./lib/auth.js.coffee
#= require ./lib/i18n.js.coffee
#= require ./lib/store.js.coffee
#= require ./lib/collection.js.coffee
#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views
#= require ./lib/interface_handle.js.coffee

class App extends Spine.Controller
  @view: (name) ->
    template = ( params = {} ) =>

      # define print name helper
      params.P = ( item, row = {} ) ->
        return '-' if item is undefined
        return '-' if item is ''
        return item if !item

        # if date is a object, get name of the object
        if typeof item is 'object'
          if item.displayNameLong
            return item.displayNameLong()
          else if item.displayName
            return item.displayName()
          return item.name

        # execute callback on content
        if row.callback
          return row.callback( item )

        # return raw data
        item

      # define translation helper
      params.T = ( item ) ->
        App.i18n.translateContent( item )

      # define translation inline helper
      params.Ti = ( item ) ->
        App.i18n.translateInline( item )

      # define linkify helper
      params.L = ( item ) ->
        window.linkify( item )

      # define template
      JST["app/views/#{name}"](params)
    template

window.App = App