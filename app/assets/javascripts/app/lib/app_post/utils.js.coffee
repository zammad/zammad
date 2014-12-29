class App.Utils

  # textCleand = App.Utils.textCleanup( rawText )
  @textCleanup: ( ascii ) ->
    $.trim( ascii )
      .replace(/(\r\n|\n\r)/g, "\n")  # cleanup
      .replace(/\r/g, "\n")           # cleanup
      .replace(/[ ]\n/g, "\n")          # remove tailing spaces
      .replace(/\n{3,9}/g, "\n\n")    # remove multible empty lines

  # htmlEscapedAndLinkified = App.Utils.text2html( rawText )
  @text2html: ( ascii ) ->
    ascii = @textCleanup(ascii)
    #ascii = @htmlEscape(ascii)
    ascii = @linkify(ascii)
    ascii = '<div>' + ascii.replace(/\n/g, '</div><div>') + '</div>'
    ascii.replace(/<div><\/div>/g, '<div><br></div>')

  # htmlEscaped = App.Utils.htmlEscape( rawText )
  @htmlEscape: ( ascii ) ->
    ascii.replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;')

  # htmlEscapedAndLinkified = App.Utils.linkify( rawText )
  @linkify: (ascii) ->
    window.linkify( ascii )

  # quotedText = App.Utils.quote( rawText )
  @quote: (ascii) ->
    ascii = @textCleanup(ascii)
    $.trim( ascii )
      .replace /^(.*)$/mg, (match) =>
        if match
          '> ' + match
        else
          '>'