class App.Utils

  # textCleand = App.Utils.textCleanup( rawText )

  @textCleanup: ( ascii ) ->
    $.trim( ascii )
      .replace(/(\r\n|\n\r)/g, "\n")  # cleanup
      .replace(/\r/g, "\n")           # cleanup
      .replace(/\s+$/gm, "\n")        # remove tailing spaces
      .replace(/\n{2,9}/gm, "\n\n")   # remove multible empty lines

  # htmlEscapedAndLinkified = App.Utils.text2html( rawText )

  @text2html: ( ascii ) ->
    ascii = @textCleanup(ascii)
    #ascii = @htmlEscape(ascii)
    ascii = @linkify(ascii)
    ascii.replace( /\n/g, '<br>' )

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