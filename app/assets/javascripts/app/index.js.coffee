#s#= require json2
#= require ./lib/core/jquery-1.8.1.min.js
#= require ./lib/core/jquery-ui-1.8.23.custom.min.js
#= require ./lib/core/underscore-1.3.3.js

#not_used= require_tree ./lib/spine
#= require ./lib/spine/spine.js
#= require ./lib/spine/ajax.js
#= require ./lib/spine/route.js

#not_used= require_tree ./lib/bootstrap
#= require ./lib/bootstrap/bootstrap-dropdown.js
#= require ./lib/bootstrap/bootstrap-tooltip.js
#= require ./lib/bootstrap/bootstrap-popover.js
#= require ./lib/bootstrap/bootstrap-modal.js
#= require ./lib/bootstrap/bootstrap-tab.js
#= require ./lib/bootstrap/bootstrap-transition.js

#= require_tree ./lib/base

#not_used= require_tree ./lib
#= require_self
#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views

#= require_tree ./lib/app

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