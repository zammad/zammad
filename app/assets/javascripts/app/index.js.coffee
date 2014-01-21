
#= require_self
#= require_tree ./lib/app_init
#= require ./config.js.coffee
#= require_tree ./models
#= require_tree ./controllers
#= require_tree ./views
#= require_tree ./lib/app_post

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
          return row.callback( item, row )

        # return raw data
        item

      # define date format helper
      params.date = ( time ) ->
        return '' if !time
        s = ( num, digits ) ->
          while num.toString().length < digits
            num = "0" + num
          num

        timeObject = new Date(time)
        d = s( timeObject.getDate(), 2 )
        m = s( timeObject.getMonth() + 1, 2 )
        y = timeObject.getFullYear()
        "#{y}-#{m}-#{d}"

      # define datetime format helper
      params.datetime = ( time ) ->
        return '' if !time
        s = ( num, digits ) ->
          while num.toString().length < digits
            num = "0" + num
          num

        timeObject = new Date(time)
        d = s( timeObject.getDate(), 2 )
        m = s( timeObject.getMonth() + 1, 2 )
        y = timeObject.getFullYear()
        S = s( timeObject.getSeconds(), 2 )
        M = s( timeObject.getMinutes(), 2 )
        H = s( timeObject.getHours(), 2 )
        "#{y}-#{m}-#{d} #{H}:#{M}:#{S}"

      # define decimal format helper
      params.decimal = ( data, positions = 2 ) ->
        return '' if !data
        s = ( num, digits ) ->
          while num.toString().length < digits
            num = num + "0"
          num
        result = data.toString().match(/^(.+?)\.(.+?)$/)
        if !result || !result[2]
          return "#{data}." + s( 0, positions ).toString()
        length = result[2].toString().length
        diff = positions - length
        if diff > 0
          return "#{result[1]}." + s( result[2], positions ).toString()
        "#{result[1]}.#{result[2].substr(0,positions)}"

      # define translation helper
      params.T = ( item, args... ) ->
        App.i18n.translateContent( item, args )

      # define translation inline helper
      params.Ti = ( item, args...  ) ->
        App.i18n.translateInline( item, args )

      # define linkify helper
      params.L = ( item ) ->
        if item && typeof item is 'string'
          return window.linkify( item )
        item

      # define config helper
      params.C = ( key ) ->
        App.Config.get( key )

      # define session helper
      params.S = ( key ) ->
        App.Session.get( key )

      # define template
      JST["app/views/#{name}"](params)
    template

window.App = App
