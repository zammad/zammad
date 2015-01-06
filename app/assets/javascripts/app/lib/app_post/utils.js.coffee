class App.Utils

  # textCleand = App.Utils.textCleanup( rawText )
  @textCleanup: ( ascii ) ->
    $.trim( ascii )
      .replace(/(\r\n|\n\r)/g, "\n")  # cleanup
      .replace(/\r/g, "\n")           # cleanup
      .replace(/[ ]\n/g, "\n")        # remove tailing spaces
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

  # wrappedText = App.Utils.wrap( rawText, maxLineLength )
  @wrap: (ascii, max = 82) ->
    result        = ''
    counter_lines = 0
    lines         = ascii.split(/\n/)
    for line in lines
      counter_lines += 1
      counter_parts  = 0
      part_length    = 0
      result_part    = ''
      parts          = line.split(/\s/)
      for part in parts
        counter_parts += 1

        # put overflow of parts to result and start new line
        if (part_length + part.length) > max
          part_length = 0
          result_part = result_part.trim()
          result_part += "\n"
          result     += result_part
          result_part = ''

        part_length += part.length
        result_part += part

        # add spacer at the end
        if counter_parts isnt parts.length
          part_length += 1
          result_part += ' '

      # put parts to result
      result     += result_part
      result_part = ''

      # add new line
      if counter_lines isnt lines.length
        result += "\n"
    result

  # quotedText = App.Utils.quote( rawText )
  @quote: (ascii, max = 82) ->
    ascii = @textCleanup(ascii)
    ascii = @wrap(ascii, max)
    $.trim( ascii )
      .replace /^(.*)$/mg, (match) =>
        if match
          '> ' + match
        else
          '>'

  @htmlRemoveTags: (textarea) ->
    # remove tags, keep content
    textarea.find('a, div, span, li, ul, ol, a, hr, blockquote, br').replaceWith( ->
      $(@).contents()
    )

  @htmlRemoveRichtext: (textarea) ->

    # remove style and class
    textarea.find('div, span, li, ul, ol, a').removeAttr( 'style' ).removeAttr( 'class' ).removeAttr( 'title' )

    # remove tags, keep content
    textarea.find('a, li, ul, ol, a, hr').replaceWith( ->
      $(@).contents()
    )

  @htmlClanup: (textarea) ->

    # remove style and class
    textarea.find('div, span, li, ul, ol, a').removeAttr( 'style' ).removeAttr( 'class' ).removeAttr( 'title' )

    # remove tags & content
    textarea.find('hr').remove()

    # remove tags, keep content
    textarea.find('a').replaceWith( ->
      $(@).contents()
    )

    # replace tags with generic div
    # New type of the tag
    replacementTag = 'div';

    # Replace all a tags with the type of replacementTag
    textarea.find('h1, h2, h3, h4, h5, h6').each( ->
      outer = this.outerHTML;

      # Replace opening tag
      regex = new RegExp('<' + this.tagName, 'i');
      newTag = outer.replace(regex, '<' + replacementTag);

      # Replace closing tag
      regex = new RegExp('</' + this.tagName, 'i');
      newTag = newTag.replace(regex, '</' + replacementTag);

      $(@).replaceWith(newTag);
    )

