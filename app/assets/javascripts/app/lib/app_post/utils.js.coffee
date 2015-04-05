class App.Utils

  # textCleand = App.Utils.textCleanup( rawText )
  @textCleanup: ( ascii ) ->
    $.trim( ascii )
      .replace(/(\r\n|\n\r)/g, "\n")  # cleanup
      .replace(/\r/g, "\n")           # cleanup
      .replace(/[ ]\n/g, "\n")        # remove tailing spaces
      .replace(/\n{3,20}/g, "\n\n")    # remove multible empty lines

  # htmlEscapedAndLinkified = App.Utils.text2html( rawText )
  @text2html: ( ascii ) ->
    ascii = @textCleanup(ascii)
    #ascii = @htmlEscape(ascii)
    ascii = @linkify(ascii)
    ascii = '<div>' + ascii.replace(/\n/g, '</div><div>') + '</div>'
    ascii.replace(/<div><\/div>/g, '<div><br></div>')

  # rawText = App.Utils.html2text( html )
  @html2text: ( html ) ->

    # remove not needed new lines
    html = html.replace(/>\n/g, '>')

    # insert new lines
    html = html
      .replace(/<br(|.+?)>/g, "\n")
      .replace(/<br\/>/g, "\n")
      .replace(/<(div)(|.+?)>/g, "")
      .replace(/<(p|blockquote|form|textarea|address|tr)(|.+?)>/g, "\n")
      .replace(/<\/(div|p|blockquote|form|textarea|address|tr)>/g, "\n")

    # trim and cleanup
    $('<div>' + html + '</div>').text().trim()
      .replace(/(\r\n|\n\r)/g, "\n")  # cleanup
      .replace(/\r/g, "\n")           # cleanup
      .replace(/\n{3,20}/g, "\n\n")   # remove multible empty lines

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

  # htmlEscaped = App.Utils.htmlEscape( rawText )
  @htmlEscape: ( ascii ) ->
    ascii.replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;')

  # textWithoutTags = App.Utils.htmlRemoveTags( html )
  @htmlRemoveTags: (html) ->

    # remove tags, keep content
    html.find('div, span, p, li, ul, ol, a, b, u, i, label, small, strong, strike, pre, code, center, blockquote, form, textarea, font, address, table, thead, tbody, tr, td, h1, h2, h3, h4, h5, h6').replaceWith( ->
      $(@).contents()
    )

    # remove tags & content
    html.find('div, span, p, li, ul, ol, a, b, u, i, label, small, strong, strike, pre, code, center, blockquote, form, textarea, font, table, thead, tbody, tr, td, h1, h2, h3, h4, h5, h6, br, hr, img, input, select, button, style, applet, canvas, script, frame, iframe').remove()

    html

  # htmlOnlyWithRichtext = App.Utils.htmlRemoveRichtext( html )
  @htmlRemoveRichtext: (html) ->

    # remove style and class
    @_removeAttributes( html )

    # remove tags, keep content
    html.find('li, ul, ol, a, b, u, i, label, small, strong, strike, pre, code, center, blockquote, form, textarea, font, address, table, thead, tbody, tr, td, h1, h2, h3, h4, h5, h6').replaceWith( ->
      $(@).contents()
    )

    # remove tags & content
    html.find('li, ul, ol, a, b, u, i, label, small, strong, strike, pre, code, center, blockquote, form, textarea, font, address, table, thead, tbody, tr, td, h1, h2, h3, h4, h5, h6, hr, img, input, select, button, style, applet, canvas, script, frame, iframe').remove()

    html

  # cleanHtmlWithRichText = App.Utils.htmlCleanup( html )
  @htmlCleanup: (html) ->

    # remove style and class
    @_removeAttributes( html )

    # remove tags, keep content
    html.find('a, font, small, time').replaceWith( ->
      $(@).contents()
    )

    # replace tags with generic div
    # New type of the tag
    replacementTag = 'div';

    # Replace all a tags with the type of replacementTag
    html.find('h1, h2, h3, h4, h5, h6, textarea').each( ->
      outer = this.outerHTML;

      # Replace opening tag
      regex = new RegExp('<' + this.tagName, 'i');
      newTag = outer.replace(regex, '<' + replacementTag);

      # Replace closing tag
      regex = new RegExp('</' + this.tagName, 'i');
      newTag = newTag.replace(regex, '</' + replacementTag);

      $(@).replaceWith(newTag);
    )

    # remove tags & content
    html.find('form, font, hr, img, input, select, button, style, applet, canvas, script, frame, iframe').remove()

    html

  @_removeAttributes: (html) ->
    html.find('div, span, p, li, ul, ol, a, b, u, i, label, small, strong, strike, pre, code, center, blockquote, h1, h2, h3, h4, h5, h6')
      .removeAttr( 'style' )
      .removeAttr( 'class' )
      .removeAttr( 'title' )
    html

  # signatureNeeded = App.Utils.signatureCheck( message, signature )
  @signatureCheck: (message, signature) ->
    messageText   = $( '<div>' + message + '</div>' ).text().trim()
    messageText   = messageText.replace(/(\n|\r|\t)/g, '')
    signatureText = $( '<div>' + signature + '</div>' ).text().trim()
    signatureText = signatureText.replace(/(\n|\r|\t)/g, '')

    quote = (str) ->
      (str + '').replace(/[.?*+^$[\]\\(){}|-]/g, "\\$&")

    #console.log('SC', messageText, signatureText, quote(signatureText))
    regex = new RegExp( quote(signatureText), 'mi' )
    if messageText.match(regex)
      false
    else
      true

  # messageWithMarker = App.Utils.signatureIdentify( message, false )
  @signatureIdentify: (message, test = false) ->
    textToSearch = @html2text( message )

    # count lines, if we do have lower the 10, ignore this
    textToSearchInLines = textToSearch.split("\n")
    if !test
      return message if textToSearchInLines.length < 10

    quote = (str) ->
      (str + '').replace(/[.?*+^$[\]\\(){}|-]/g, "\\$&")

    cleanup = (str) ->
      if str.match(/(<|>|&)/)
        str = str.replace(/(<|>|&).+?$/, '').trim()
      str

    # search for signature seperator "--\n"
    markers = []
    searchForSeperator = (textToSearchInLines, markers) ->
      lineCount = 0
      for line in textToSearchInLines
        lineCount += 1
        if line && line.match( /^\s{0,10}--\s{0,10}$/ )
          marker =
            line:      line
            lineCount: lineCount
            type:      'seperator'
          markers.push marker
          return
    searchForSeperator(textToSearchInLines, markers)

    # search for Thunderbird
    searchForThunderbird = (textToSearchInLines, markers) ->
      lineCount = 0
      for line in textToSearchInLines
        lineCount += 1

        # Am 04.03.2015 um 12:47 schrieb Alf Aardvark:
        if line && line.match( /^(Am)\s.{6,20}\s(um)\s.{3,10}\s(schrieb)\s.{1,250}:/ )
          marker =
            line:      cleanup(line)
            lineCount: lineCount
            type:      'thunderbird'
          markers.push marker
          return

        # Thunderbird default - http://kb.mozillazine.org/Reply_header_settings
        # On 01-01-2007 11:00 AM, Alf Aardvark wrote:
        if line && line.match( /^(On)\s.{6,20}\s.{3,10},\s.{1,250}(wrote):/ )
          marker =
            line:      cleanup(line)
            lineCount: lineCount
            type:      'thunderbird'
          markers.push marker
          return

        # http://kb.mozillazine.org/Reply_header_settings
        # Alf Aardvark wrote, on 01-01-2007 11:00 AM:
        if line && line.match( /^.{1,250}\s(wrote),\son\s.{3,20}:/ )
          marker =
            line:      cleanup(line)
            lineCount: lineCount
            type:      'thunderbird'
          markers.push marker
          return
    searchForThunderbird(textToSearchInLines, markers)

    # search for Apple Mail
    searchForAppleMail = (textToSearchInLines, markers) ->
      lineCount = 0
      for line in textToSearchInLines
        lineCount += 1

        # On 01/04/15 10:55, Bob Smith wrote:
        if line && line.match( /^(On)\s.{6,20}\s.{3,10}\s.{1,250}\s(wrote):/ )
          marker =
            line:      cleanup(line)
            lineCount: lineCount
            type:      'apple'
          markers.push marker
          return

        # Am 03.04.2015 um 20:58 schrieb Martin Edenhofer <me@znuny.ink>:
        if line && line.match( /^(Am)\s.{6,20}\s(um)\s.{3,10}\s(schrieb)\s.{1,250}:/ )
          marker =
            line:      cleanup(line)
            lineCount: lineCount
            type:      'apple'
          markers.push marker
          return
    searchForAppleMail(textToSearchInLines, markers)

    # search for otrs
    # 25.02.2015 10:26 - edv hotline wrote:
    # 25.02.2015 10:26 - edv hotline schrieb:
    searchForOtrs = (textToSearchInLines, markers) ->
      lineCount = 0
      for line in textToSearchInLines
        lineCount += 1
        if line && line.match( /^.{6,10}\s.{3,10}\s-\s.{1,250}\s(wrote|schrieb):/ )
          marker =
            line:      cleanup(line)
            lineCount: lineCount
            type:      'Otrs'
          markers.push marker
          return
    searchForOtrs(textToSearchInLines, markers)

    # search for Ms
    # From: Martin Edenhofer via Znuny Support [mailto:support@znuny.inc]
    # Send: Donnerstag, 2. April 2015 10:00
    # To/Cc/Bcc: xxx
    # Subject: xxx
    # - or -
    # From: xxx
    # To/Cc/Bcc: xxx
    # Date: 01.04.2015 12:41
    # Subject: xxx
    searchForMs = (textToSearchInLines, markers) ->
      lineCount          = 0
      fromFound          = undefined
      foundInLines       = 0
      subjectWithinLines = 5
      for line in textToSearchInLines
        lineCount += 1

        # find Sent
        if fromFound
          if line && line.match( /^(Subject|Betreff):\s.+?/)
            marker =
              line:      fromFound
              lineCount: lineCount
              type:      'Ms'
            markers.push marker
            return
          if lineCount > ( foundInLines + subjectWithinLines )
            fromFound = undefined

        # find From
        else
          if line && line.match( /^(From|Von):\s.+?/ )
            fromFound    = line.replace(/\s{0,5}(\[|<).+?(\]|>)/g, '')
            foundInLines = lineCount
    searchForMs(textToSearchInLines, markers)

    # marker template
    markerTemplate = '<span class="js-signatureMarker"></span>'

    # search for zammad
    # <div data-signature="true" data-signature-id=".{1,3}">
    if !markers || !markers[0]
      regex = new RegExp( "(<div data-signature=\"true\" data-signature-id=\".{1,3}\">)" )
      if message.match( regex )
        return message.replace( regex, "#{markerTemplate}\$1" )

    # search for <blockquote type="cite">
    # <blockquote type="cite">
    if !markers || !markers[0]
      regex = new RegExp( "(<blockquote type=\"cite\">)" )
      if message.match( regex )
        return message.replace( regex, "#{markerTemplate}\$1" )

    # gmail
    # <div class="ecxgmail_quote">
    if !markers || !markers[0]
      regex = new RegExp( "(<blockquote class=\"(ecxgmail_quote|gmail_quote)\">)" )
      if message.match( regex )
        return message.replace( regex, "#{markerTemplate}\$1" )

    # if no marker is found, return
    return message if !markers || !markers[0]

    # get first marker
    markers = _.sortBy(markers, 'lineCount')
    if markers[0].type is 'seperator'
      regex = new RegExp( "\>(\s{0,10}#{quote(markers[0].line)})\s{0,10}\<" )
      message.replace( regex, ">#{markerTemplate}\$1<" )
    else
      regex = new RegExp( "\>(\s{0,10}#{quote(markers[0].line)})" )
      message.replace( regex, ">#{markerTemplate}\$1" )

  # textReplaced = App.Utils.replaceTags( template, { user: { firstname: 'Bob', lastname: 'Smith' } } )
  @replaceTags: (template, objects) ->
    template = template.replace( /#\{\s{0,2}(.+?)\s{0,2}\}/g, ( index, key ) ->
      levels  = key.split(/\./)
      dataRef = objects
      for level in levels
        if dataRef[level]
          dataRef = dataRef[level]
      if typeof dataRef is 'function'
        value = dataRef()
      else if typeof dataRef is 'string'
        value = dataRef
      else
        value = ''
      #console.log( "tag replacement #{key}, #{value} env: ", objects)
      value
    )

  # true|false = App.Utils.lastLineEmpty( message )
  @lastLineEmpty: (message) ->
    messageCleanup = message.replace(/>\s+</g, '><').replace(/(\n|\r|\t)/g, '').trim()
    return true if messageCleanup.match(/<(br|\s+?|\/)>$/im)
    return true if messageCleanup.match(/<div(|\s.+?)><\/div>$/im)
    false

  # cleanString = App.Utils.htmlAttributeCleanup( string )
  @htmlAttributeCleanup: (string) ->
    string.replace(/((?![-a-zA-Z0-9_]+).|\n|\r|\t)/gm, '')

  # diff = App.Utils.formDiff( dataNow, dataLast )
  @formDiff: ( dataNowRaw, dataLastRaw ) ->

    # do type convertation to compare it against form
    dataNow = clone(dataNowRaw)
    @_formDiffNormalizer(dataNow)
    dataLast = clone(dataLastRaw)
    @_formDiffNormalizer(dataLast)

    @_formDiffChanges( dataNow, dataLast )

  @_formDiffChanges: (dataNow, dataLast, changes = {}) ->
    for dataNowkey, dataNowValue of dataNow
      if dataNow[dataNowkey] isnt dataLast[dataNowkey]
        if _.isArray( dataNow[dataNowkey] ) && _.isArray( dataLast[dataNowkey] )
          diff = _.difference( dataNow[dataNowkey], dataLast[dataNowkey] )
          if !_.isEmpty( diff )
            changes[dataNowkey] = diff
        else if _.isObject( dataNow[dataNowkey] ) &&  _.isObject( dataLast[dataNowkey] )
          changes = @_formDiffChanges( dataNow[dataNowkey], dataLast[dataNowkey], changes )
        else
          changes[dataNowkey] = dataNow[dataNowkey]
    changes

  @_formDiffNormalizer: (data) ->
    return undefined if data is undefined
    return if !@_formDiffNormalizerCheckConstructor( data )

    if _.isArray( data )
      for i in [0...data.length]
        if @_formDiffNormalizerCheckConstructor( data[i] )
          data[i] = @_formDiffNormalizer( data[i] )
        else
          data[i] = undefined
    else if _.isObject( data )
      for key, value of data
        if _.isArray( data[key] )
          @_formDiffNormalizer( data[key] )
        else if _.isObject( data[key] )
          @_formDiffNormalizer( data[key] )
        else if @_formDiffNormalizerCheckConstructor( data[key] )
          data[key] = @_formDiffNormalizerItem( key, data[key] )
    else
      @_formDiffNormalizerItem( '', data )

  @_formDiffNormalizerCheckConstructor: (data) ->
    return true if !data
    return true if !data.constructor
    name = data.constructor.name
    return true if !name
    return true if name is 'Object'
    return true if name is 'Array'
    return true if name is 'String'
    return true if name is 'Number'
    false

  @_formDiffNormalizerItem: (key, value) ->

    # handel owner/nobody behavior
    if key is 'owner_id' && value.toString() is '1'
      value = ''
    else if typeof value is 'number'
      value = value.toString()

    # handle null/undefined behavior - we just handle both as the same
    else if value is null
      value = undefined

    value

  # check if attachment is referenced in message
  @checkAttachmentReference: (message) ->
    return false if !message
    return true if message.match(/attachment/i)
    attachmentTranslated = App.i18n.translateContent('Attachment')
    attachmentTranslatedRegExp = new RegExp( attachmentTranslated, 'i' )
    return true if message.match( attachmentTranslatedRegExp )
    false

  # human readable file size
  @humanFileSize: (size) =>
    if size > ( 1024 * 1024 )
      size = Math.round( size / ( 1024 * 1024 ) ) + ' MB'
    else if size > 1024
      size = Math.round( size / 1024 ) + ' KB'
    else
      size = size + ' Bytes'
    size
