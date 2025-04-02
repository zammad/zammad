class App.Channel extends App.Model
  @configure 'Channel', 'adapter', 'area', 'options', 'group_id', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/channels'

  displayName: ->
    name = ''
    if @options
      if @options.inbound?.options?.user
        if @options.inbound.options.host
          name += "#{@options.inbound.options.user}@#{@options.inbound.options.host} "
        else
          name += "#{@options.inbound.options.user} "
      if @options.inbound?.adapter
        name += "(#{@options.inbound.adapter})"
      if @options.outbound
        if name != ''
          name += ' / '
        if @options.outbound.options?.host
          name += "#{@options.outbound.options.host} "
        if @options.outbound.adapter
          name += "(#{@options.outbound.adapter})"
    if name == ''
      name = '-'
    name
