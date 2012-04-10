# jQuery.tmpl.js utilities

$ = jQuery ? require("jqueryify")

$.fn.item = ->
  item = $(@)
  item = item.data("item") or item.tmplItem?().data
  item?.reload?()
  item

$.fn.forItem = (item) ->
  @filter ->
    compare = $(@).item()
    return item.eql?(compare) or item is compare

