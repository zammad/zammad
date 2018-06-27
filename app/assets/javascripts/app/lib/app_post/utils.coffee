# coffeelint: disable=no_unnecessary_double_quotes
class App.Utils
  @mapTagAttributes:
    'TABLE': ['align', 'bgcolor', 'border', 'cellpadding', 'cellspacing', 'frame', 'rules', 'sortable', 'summary', 'width', 'style']
    'TD': ['abbr', 'align', 'axis', 'colspan', 'headers', 'rowspan', 'valign', 'width', 'style']
    'TH': ['abbr', 'align', 'axis', 'colspan', 'headers', 'rowspan', 'scope', 'sorted', 'valign', 'width', 'style']
    'TR': ['width', 'style']
    'A': ['href', 'hreflang', 'name', 'rel']
    'IMG': ['align', 'alt', 'border', 'height', 'src', 'srcset', 'width', 'style']

  @mapCss:
    'TABLE': [
      'background', 'background-color', 'color', 'font-size', 'vertical-align',
      'margin', 'margin-top', 'margin-right', 'margin-bottom', 'margin-left',
      'padding', 'padding-top', 'padding-right', 'padding-bottom', 'padding-left',
      'text-align',
      'border', 'border-top', 'border-right', 'border-bottom', 'border-left', 'border-collapse', 'border-style', 'border-spacing',

      'border-top-width', 'border-right-width', 'border-bottom-width', 'border-left-width',
      'border-top-color', 'border-right-color', 'border-bottom-color', 'border-left-color',
      'border-top-style', 'border-right-style', 'border-bottom-style', 'border-left-style',
    ]
    'TH': [
      'background', 'background-color', 'color', 'font-size', 'vertical-align',
      'margin', 'margin-top', 'margin-right', 'margin-bottom', 'margin-left',
      'padding', 'padding-top', 'padding-right', 'padding-bottom', 'padding-left',
      'text-align',
      'border', 'border-top', 'border-right', 'border-bottom', 'border-left', 'border-collapse', 'border-style', 'border-spacing',

      'border-top-width', 'border-right-width', 'border-bottom-width', 'border-left-width',
      'border-top-color', 'border-right-color', 'border-bottom-color', 'border-left-color',
      'border-top-style', 'border-right-style', 'border-bottom-style', 'border-left-style',

    ]
    'TR': [
      'background', 'background-color', 'color', 'font-size', 'vertical-align',
      'margin', 'margin-top', 'margin-right', 'margin-bottom', 'margin-left',
      'padding', 'padding-top', 'padding-right', 'padding-bottom', 'padding-left',
      'text-align',
      'border', 'border-top', 'border-right', 'border-bottom', 'border-left', 'border-collapse', 'border-style', 'border-spacing',

      'border-top-width', 'border-right-width', 'border-bottom-width', 'border-left-width',
      'border-top-color', 'border-right-color', 'border-bottom-color', 'border-left-color',
      'border-top-style', 'border-right-style', 'border-bottom-style', 'border-left-style',

    ]
    'TD': [
      'background', 'background-color', 'color', 'font-size', 'vertical-align',
      'margin', 'margin-top', 'margin-right', 'margin-bottom', 'margin-left',
      'padding', 'padding-top', 'padding-right', 'padding-bottom', 'padding-left',
      'text-align',
      'border', 'border-top', 'border-right', 'border-bottom', 'border-left', 'border-collapse', 'border-style', 'border-spacing',

      'border-top-width', 'border-right-width', 'border-bottom-width', 'border-left-width',
      'border-top-color', 'border-right-color', 'border-bottom-color', 'border-left-color',
      'border-top-style', 'border-right-style', 'border-bottom-style', 'border-left-style',

    ]
    'IMG': [
      'width', 'height',
    ]

  # textCleand = App.Utils.textCleanup(rawText)
  @textCleanup: (ascii) ->
    $.trim( ascii )
      .replace(/(\r\n|\n\r)/g, "\n")  # cleanup
      .replace(/\r/g, "\n")           # cleanup
      .replace(/[ ]\n/g, "\n")        # remove tailing spaces
      .replace(/\n{3,20}/g, "\n\n")   # remove multiple empty lines

  # htmlEscapedAndLinkified = App.Utils.text2html(rawText)
  @text2html: (ascii) ->
    ascii = @textCleanup(ascii)
    #ascii = @htmlEscape(ascii)
    ascii = @linkify(ascii)
    ascii = '<div>' + ascii.replace(/\n/g, '</div><div>') + '</div>'
    ascii.replace(/<div><\/div>/g, '<div><br></div>')

  # rawText = App.Utils.html2text(html, no_trim)
  @html2text: (html, no_trim) ->
    return html if !html

    if no_trim
      html = html
        .replace(/([A-z])\n([A-z])/gm, '$1 $2')
        .replace(/\n|\r/g, '')
        .replace(/<(br|hr)>/g, "\n")
        .replace(/<(br|hr)\/>/g, "\n")
        .replace(/<\/(div|p|blockquote|form|textarea|address|tr)>/g, "\n")
      return $('<div>' + html + '</div>').text()

    # remove not needed new lines
    html = html.replace(/([A-z])\n([A-z])/gm, '$1 $2')
      .replace(/>\n/g, '>')
      .replace(/\n|\r/g, '')

    # trim and cleanup
    html = html
      .replace(/<(br|hr)>/g, "\n")
      .replace(/<(br|hr)\/>/g, "\n")
      .replace(/<(div)(|.+?)>/g, "")
      .replace(/<(p|blockquote|form|textarea|address|tr)(|.+?)>/g, "\n")
      .replace(/<\/(div|p|blockquote|form|textarea|address|tr)>/g, "\n")
    $('<div>' + html + '</div>').text().trim()
      .replace(/\n{3,20}/g, "\n\n")   # remove multiple empty lines

  # htmlEscapedAndLinkified = App.Utils.linkify(rawText)
  @linkify: (string) ->
    window.linkify(string)

  # htmlEscapedAndPhoneified = App.Utils.phoneify(rawText)
  @phoneify: (string) ->
    return string if _.isEmpty(string)
    string = string.replace(/[^0-9,\+,#,\*]+/g, '')
      .replace(/(.)\+/, '$1')
    "tel:#{string}"

  # wrappedText = App.Utils.wrap(rawText, maxLineLength)
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

  # quotedText = App.Utils.quote(rawText)
  @quote: (ascii, max = 82) ->
    ascii = @textCleanup(ascii)
    ascii = @wrap(ascii, max)
    $.trim(ascii)
      .replace /^(.*)$/mg, (match) ->
        if match
          '> ' + match
        else
          '>'

  @escapeRegExp: (str) ->
    return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")

  # htmlEscaped = App.Utils.htmlEscape(rawText)
  @htmlEscape: (ascii) ->
    return ascii if !ascii
    return ascii if !ascii.replace
    ascii.replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;')

  # App.Utils.htmlStrip(element)
  @htmlStrip: (element) ->
    loop
      el = element.get(0)
      break if !el
      child = el.firstChild
      break if !child
      break if child.nodeType isnt 1 || child.tagName isnt 'BR'
      break if !child.remove
      child.remove()

    loop
      el = element.get(0)
      break if !el
      child = el.lastChild
      break if !child
      break if child.nodeType isnt 1 || child.tagName isnt 'BR'
      break if !child.remove
      child.remove()

  # true|false = App.Utils.htmlLastLineEmpty(element)
  @htmlLastLineEmpty: (element) ->
    el = element.get(0)
    return false if !el
    child = el.lastChild
    return false if !child
    return false if child.nodeType isnt 1 || child.tagName isnt 'BR'
    true

  # textWithoutTags = App.Utils.htmlRemoveTags(html)
  @htmlRemoveTags: (html) ->
    html = @_checkTypeOf(html)

    # remove comments
    @_removeComments(html)

    # remove word markup
    @_removeWordMarkup(html)

    # remove tags, keep content
    html.find('div, span, p, li, ul, ol, a, b, u, i, label, small, strong, strike, pre, code, center, blockquote, form, fieldset, textarea, font, address, table, thead, tbody, tr, th, td, h1, h2, h3, h4, h5, h6').replaceWith( ->
      $(@).contents()
    )

    # remove tags & content
    html.find('div, span, p, li, ul, ol, a, b, u, i, label, small, strong, strike, pre, code, center, blockquote, form, fieldset, textarea, font, table, thead, tbody, tr, th, td, h1, h2, h3, h4, h5, h6, br, hr, img, svg, input, select, button, style, applet, embed, noframes, canvas, script, frame, iframe, meta, link, title, head').remove()

    html

  # htmlOnlyWithRichtext = App.Utils.htmlRemoveRichtext(html)
  @htmlRemoveRichtext: (html, parent = true) ->
    return html if !html
    html = @_checkTypeOf(html)

    # remove comments
    @_removeComments(html)

    # remove word markup
    @_removeWordMarkup(html)

    # remove tags, keep content
    html.find('li, ul, ol, a, b, u, i, label, small, strong, strike, pre, code, center, blockquote, form, fieldset, textarea, font, address, table, thead, tbody, tr, th, td, h1, h2, h3, h4, h5, h6').replaceWith( ->
      $(@).contents()
    )

    # remove tags & content
    html.find('li, ul, ol, a, b, u, i, label, small, strong, strike, pre, code, center, blockquote, form, fieldset, textarea, font, address, table, thead, tbody, tr, th, td, h1, h2, h3, h4, h5, h6, hr, img, svg, input, select, button, style, applet, embed, noframes, canvas, script, frame, iframe, meta, link, title, head').remove()

    # remove style and class
    @_removeAttributes(html, parent)

    html

  # cleanHtmlWithRichText = App.Utils.htmlCleanup(html)
  @htmlCleanup: (html) ->
    return html if !html
    html = @_checkTypeOf(html)

    # remove comments
    @_removeComments(html)

    # remove word markup
    @_removeWordMarkup(html)

    # remove tags, keep content
    html.find('font, small, time, form, label').replaceWith( ->
      $(@).contents()
    )

    # replace tags with generic div
    # New type of the tag
    replacementTag = 'div';

    # Replace all x tags with the type of replacementTag
    html.find('textarea').each( ->
      outer = @outerHTML

      # Replace opening tag
      regex = new RegExp('<' + @tagName, 'i')
      newTag = outer.replace(regex, '<' + replacementTag)

      # Replace closing tag
      regex = new RegExp('</' + @tagName, 'i')
      newTag = newTag.replace(regex, '</' + replacementTag)

      $(@).replaceWith(newTag)
    )

    # remove tags & content
    html.find('font, svg, input, select, button, style, applet, embed, noframes, canvas, script, frame, iframe, meta, link, title, head, fieldset').remove()

    # remove style and class
    @_cleanAttributes(html)

    html

  @_checkTypeOf: (item) ->
    return item if typeof item isnt 'string'

    try
      result = $(item)

      # if we have more then on element at first level
      if result.length > 1
        return $("<div>#{item}</div>")

      # if we have just a text string without html markup
      if !result || !result.get(0)
        return $("<div>#{item}</div>")

      return result
    catch err
      return $("<div>#{item}</div>")

  @_cleanAttribute: (element) ->
    return if !element

    if @mapTagAttributes[element.nodeName]
      atts = element.attributes
      for att in atts
        if att && att.name && !_.contains(@mapTagAttributes[element.nodeName], att.name)
          element.removeAttribute(att.name)
    else
      @_removeAttribute(element)

    if @mapCss[element.nodeName]
      elementStyle = element.style
      styleOld = ''
      for prop in elementStyle
        styleOld += "#{prop}:#{elementStyle[prop]};"

      if styleOld && styleOld.split
        styleNew = ''
        for local_pear in styleOld.split(';')
          prop = local_pear.split(':')
          if prop[0] && prop[0].trim
            key = prop[0].trim()
            if _.contains(@mapCss[element.nodeName], key)
              styleNew += "#{local_pear};"
        if styleNew isnt ''
          element.setAttribute('style', styleNew)
        else
          element.removeAttribute('style')

  @_cleanAttributes: (html, parent = true) ->
    if parent
      html.each((index, element) => @_cleanAttribute(element) )
    html.find('*').each((index, element) => @_cleanAttribute(element) )
    html

  @_removeAttribute: (element) ->
    return if !element
    $element = $(element)
    for att in element.attributes
      if att && att.name
        element.removeAttribute(att.name)
        #$element.removeAttr(att.name)

    $element.removeAttr('style')
      .removeAttr('class')
      .removeAttr('lang')
      .removeAttr('type')
      .removeAttr('align')
      .removeAttr('id')
      .removeAttr('wrap')
      .removeAttr('title')
      .removeAttrs(/data-/)

  @_removeAttributes: (html, parent = true) ->
    if parent
      html.each((index, element) => @_removeAttribute(element) )
    html.find('*').each((index, element) => @_removeAttribute(element) )
    html

  @_removeComments: (html) ->
    html.contents().each( ->
      if @nodeType == 8
        $(@).remove()
    )
    html

  @_removeWordMarkup: (html) ->
    return html if !html.get(0)
    match = false
    htmlTmp = html.get(0).outerHTML
    regex = new RegExp('<(/w|w)\:[A-Za-z]')
    if htmlTmp.match(regex)
      match = true
      htmlTmp = htmlTmp.replace(regex, '')
    regex = new RegExp('<(/o|o)\:[A-Za-z]')
    if htmlTmp.match(regex)
      match = true
      htmlTmp = htmlTmp.replace(regex, '')
    if match
      return window.word_filter(html)
    html

  # signatureNeeded = App.Utils.signatureCheck(message, signature)
  @signatureCheck: (message, signature) ->
    messageText   = $('<div>' + message + '</div>').text().trim()
    messageText   = messageText.replace(/(\n|\r|\t)/g, '')
    signatureText = $('<div>' + signature + '</div>').text().trim()
    signatureText = signatureText.replace(/(\n|\r|\t)/g, '')

    quote = (str) ->
      (str + '').replace(/[.?*+^$[\]\\(){}|-]/g, "\\$&")

    #console.log('SC', messageText, signatureText, quote(signatureText))
    regex = new RegExp(quote(signatureText), 'mi')
    if messageText.match(regex)
      false
    else
      true

  # messageWithMarker = App.Utils.signatureIdentify(message, false)
  @signatureIdentify: (message, test = false, internal = false) ->
    textToSearch = @html2text(message)

    # if we do have less then 10 lines and less then 300 chars ignore this
    textToSearchInLines = textToSearch.split("\n")
    return message if !test && (textToSearchInLines.length < 10 && textToSearch.length < 300)

    quote = (str) ->
      (str + '').replace(/[.?*+^$[\]\\(){}|-]/g, "\\$&")

    cleanup = (str) ->
      if str.match(/(<|>|&)/)
        str = str.replace(/(.+?)(<|>|&).+?$/, "$1").trim()
      str

    # search for signature separator "--\n"
    markers = []
    searchForSeparator = (textToSearchInLines, markers) ->
      lineCount = 0
      for line in textToSearchInLines
        lineCount += 1
        if line && line.match( /^\s{0,10}--\s{0,10}$/ )
          marker =
            line:      line
            lineCount: lineCount
            type:      'separator'
          markers.push marker
          return
    searchForSeparator(textToSearchInLines, markers)

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
        if line && line.match( /^.{6,10}\s.{3,10}\s-\s.{1,250}\s(wrote|schrieb|a écrit|escribió):/ )
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
    # - or -
    # De : xxx
    # À/?/?: xxx
    # Envoyé : mercredi 29 avril 2015 17:31
    # Objet : xxx
    searchForMs = (textToSearchInLines, markers) ->
      lineCount          = 0
      fromFound          = undefined
      foundInLines       = 0
      subjectWithinLines = 5
      for line in textToSearchInLines
        lineCount += 1

        # find Sent
        if fromFound
          if line && line.match( /^(Subject|Betreff|Objet)(\s|):\s.+?/) # en/de/fr | sometimes ms adds a space to "xx : value"
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
          if line && line.match( /^(From|Von|De)(\s|):\s.+?/ ) # en/de/fr | sometimes ms adds a space to "xx : value"
            fromFound    = line.replace(/\s{0,5}(\[|<).+?(\]|>)/g, '')
            foundInLines = lineCount
    searchForMs(textToSearchInLines, markers)

    # word 14
    # edv hotline wrote:
    # edv hotline schrieb:
    searchForWord14 = (textToSearchInLines, markers) ->
      lineCount = 0
      for line in textToSearchInLines
        lineCount += 1
        if line && line.match( /^.{1,250}\s(wrote|schrieb|a écrit|escribió):/ )
          marker =
            line:      cleanup(line)
            lineCount: lineCount
            type:      'Word14'
          markers.push marker
          return
    searchForWord14(textToSearchInLines, markers)

    # gmail
    # Am 24.10.2016 18:55 schrieb "xxx" <somebody@example.com>:
    searchForGmail = (textToSearchInLines, markers) ->
      lineCount = 0
      for line in textToSearchInLines
        lineCount += 1
        if line && line.match( /.{1,250}\s(wrote|schrieb|a écrit|escribió)\s.{1,250}:/ )
          marker =
            line:      cleanup(line)
            lineCount: lineCount
            type:      'gmail'
          markers.push marker
          return
    searchForGmail(textToSearchInLines, markers)

    # marker template
    markerTemplate = '<span class="js-signatureMarker"></span>'

    # search for zammad
    # <div data-signature="true" data-signature-id=".{1,5}">
    if !markers || !markers[0] || internal
      regex = new RegExp("(<div data-signature=\"true\" data-signature-id=\".{1,5}\">)")
      if message.match(regex)
        return message.replace(regex, "#{markerTemplate}\$1")
      regex = new RegExp("(<div data-signature-id=\".{1,5}\" data-signature=\"true\">)")
      if message.match(regex)
        return message.replace(regex, "#{markerTemplate}\$1")

    # search for <blockquote type="cite">
    # <blockquote type="cite">
    if !markers || !markers[0]
      regex = new RegExp("(<blockquote type=\"cite\">)")
      if message.match(regex)
        return message.replace(regex, "#{markerTemplate}\$1")

    # gmail
    # <div class="ecxgmail_quote">
    if !markers || !markers[0]
      regex = new RegExp("(<blockquote class=\"(ecxgmail_quote|gmail_quote)\">)")
      if message.match(regex)
        return message.replace(regex, "#{markerTemplate}\$1")

    # if no marker is found, return
    return message if !markers || !markers[0]

    # get first marker
    markers = _.sortBy(markers, 'lineCount')
    if markers[0].type is 'separator'
      regex = new RegExp("\>(\s{0,10}#{quote(App.Utils.htmlEscape(markers[0].line))})\s{0,10}\<")
      message.replace(regex, ">#{markerTemplate}\$1<")
    else
      regex = new RegExp("\>(\s{0,10}#{quote(App.Utils.htmlEscape(markers[0].line))})")
      message.replace(regex, ">#{markerTemplate}\$1")

  # textReplaced = App.Utils.replaceTags( template, { user: { firstname: 'Bob', lastname: 'Smith' } } )
  @replaceTags: (template, objects) ->
    template = template.replace( /#\{\s{0,2}(.+?)\s{0,2}\}/g, (index, key) ->
      key = key.replace(/<.+?>/g, '')
      levels  = key.split(/\./)
      dataRef = objects
      for level in levels
        if level of dataRef
          dataRef = dataRef[level]
        else
          dataRef = ''
          break
      if typeof dataRef is 'function'
        value = dataRef()
      else if dataRef isnt undefined && dataRef isnt null && dataRef.toString
        value = dataRef.toString()
      else
        value = ''
      #console.log( "tag replacement #{key}, #{value} env: ", objects)
      if value is ''
        value = '-'
      value
    )

  # string = App.Utils.removeEmptyLines(stringWithEmptyLines)
  @removeEmptyLines: (string) ->
    string.replace(/^\s*[\r\n]/gm, '')

  # cleanString = App.Utils.htmlAttributeCleanup(string)
  @htmlAttributeCleanup: (string) ->
    string.replace(/((?![-a-zA-Z0-9_]+).|\n|\r|\t)/gm, '')

  # diff = App.Utils.formDiff(dataNow, dataLast)
  @formDiff: (dataNowRaw, dataLastRaw) ->
    dataNow = clone(dataNowRaw)
    @_formDiffNormalizer(dataNow)
    dataLast = clone(dataLastRaw)
    @_formDiffNormalizer(dataLast)

    @_formDiffChanges(dataNow, dataLast)

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

    if _.isArray(data)
      for i in [0...data.length]
        data[i] = @_formDiffNormalizer(data[i])
    else if _.isObject(data)
      for key, value of data
        if _.isArray(data[key])
          @_formDiffNormalizer(data[key])
        else if _.isObject( data[key] )
          @_formDiffNormalizer(data[key])
        else
          data[key] = @_formDiffNormalizerItem(key, data[key])
    else
      @_formDiffNormalizerItem('', data)

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
    matchwords = ['Attachment', 'attachment', 'Attached', 'attached', 'Enclosed', 'enclosed', 'Enclosure', 'enclosure']
    for word in matchwords

      # en
      attachmentTranslatedRegExp = new RegExp("\\W#{word}\\W", 'i')
      return word if message.match(attachmentTranslatedRegExp)

      # user locale
      attachmentTranslated = App.i18n.translateContent(word)
      attachmentTranslatedRegExp = new RegExp("\\W#{attachmentTranslated}\\W", 'i')
      return attachmentTranslated if message.match(attachmentTranslatedRegExp)
    false

  # human readable file size
  @humanFileSize: (size) ->
    if size > ( 1024 * 1024 )
      size = (Math.round( size * 10 / ( 1024 * 1024 ) ) / 10 ) + ' MB'
    else if size > 1024
      size = Math.round( size / 1024 ) + ' KB'
    else
      size = size + ' Bytes'
    size

  # format decimal
  @decimal: (data, positions = 2) ->

    # input validation
    return '' if data is undefined
    return '' if data is null

    if data.toString
      data = data.toString()

    return data if data is ''
    return data if data.match(/[A-z]/)

    format = ( num, digits ) ->
      while num.toString().length < digits
        num = num + '0'
      num

    result = data.match(/^(.+?)\.(.+?)$/)

    # add .00
    if !result || !result[2]
      return "#{data}.#{format(0, positions)}"
    length = result[2].length
    diff = positions - length

    # check length, add .00
    return "#{result[1]}.#{format(result[2], positions)}" if diff > 0

    # check length, remove longer positions
    "#{result[1]}.#{result[2].substr(0,positions)}"

  @sortByValue: (options, order = 'ASC') ->
    # sort by name
    byNames = []
    byNamesWithValue = {}
    for i, value of options
      valueTmp = value.toString().toLowerCase()
      byNames.push valueTmp
      byNamesWithValue[valueTmp] = [i, value]
    byNames = byNames.sort()

    # do a reverse, if needed
    if order == 'DESC'
      byNames = byNames.reverse()

    optionsNew = {}
    for i in byNames
      ref = byNamesWithValue[i]
      optionsNew[ref[0]] = ref[1]
    optionsNew

  @sortByKey: (options, order = 'ASC') ->
    # sort by name
    byKeys = []
    for i, value of options
      if i.toString
        iTmp = i.toString().toLowerCase()
      else
        iTmp = i
      byKeys.push iTmp
    byKeys = byKeys.sort()

    # do a reverse, if needed
    if order == 'DESC'
      byKeys = byKeys.reverse()

    optionsNew = {}
    for i in byKeys
      optionsNew[i] = options[i]
    optionsNew

  @formatTime: (num, digits) ->

    # input validation
    return '' if num is undefined
    return '' if num is null

    if num.toString
      num = num.toString()

    while num.length < digits
      num = '0' + num
    num

  @icon: (name, className = '') ->
    return if !name

    # rtl support
    # ===========
    #
    # translates @Icon('arrow-{start}') to @Icon('arrow-left') on ltr and @Icon('arrow-right') on rtl
    dictionary =
      ltr:
        start: 'left'
        end: 'right'
      rtl:
        start: 'right'
        end: 'left'
    if name.indexOf('{') > 0 # only run through the dictionary when there is a {helper}
      for key, value of dictionary[App.i18n.dir()]
        name = name.replace("{#{key}}", value)

    #
    # reverse regex
    # =============
    #
    # search: <svg class="icon icon-([^\s]+)\s([^"]*).*<\/svg>
    # replace: <%- @Icon('$1', '$2') %>
    #
    path = if window.svgPolyfill then '' else 'assets/images/icons.svg'
    "<svg class=\"icon icon-#{name} #{className}\"><use xlink:href=\"#{path}#icon-#{name}\" /></svg>"

  @getScrollBarWidth: ->
    $outer = $('<div>').css(
      visibility: 'hidden'
      width: 100
      overflow: 'scroll'
    ).appendTo('body')

    widthWithScroll = $('<div>').css(
      width: '100%'
    ).appendTo($outer).outerWidth()

    $outer.remove()

    return 100 - widthWithScroll

  @diffPositionAdd: (a, b) ->
    applyOrder = []
    newOrderMethod = (a, b, applyOrder) ->
      for position of b
        if a[position] isnt b[position]
          positionInt = parseInt(position)

          # changes to complex, whole rerender
          if _.contains(a, b[position])
            return false

          # insert new item and try next
          a.splice(positionInt, 0, b[position])
          positionNew = 0
          for positionA of a
            if b[positionA] is b[position]
              positionNew = parseInt(positionA)
              break
          apply =
            position: positionNew
            id: b[position]
          applyOrder.push apply
          newOrderMethod(a, b, applyOrder)
      true

    result = newOrderMethod(a, b, applyOrder)
    return false if !result
    applyOrder

  @textLengthWithUrl: (text, url_max_length = 23) ->
    length = 0
    return length if !text
    placeholder = Array(url_max_length + 1).join('X')
    text = text.replace(/http(s|):\/\/[-A-Za-z0-9+&@#\/%?=~_\|!:,.;]+[-A-Za-z0-9+&@#\/%=~_|]/img, placeholder)
    text.length

  @parseAddressListLocal: (line) ->
    recipients = emailAddresses.parseAddressList(line)
    result = []
    if !_.isEmpty(recipients)
      for recipient in recipients
        if recipient && recipient.address
          result.push recipient.address
      return result

    # workaround for email-addresses.js issue with this kind of
    # mail headers "From: invalid sender, realname <sender@example.com>"
    # email-addresses.js is returning null because it can't parse the
    # whole header
    if _.isEmpty(recipients) && line.match('@')
      recipients = line.split(',')
      re = /(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/
      for recipient in recipients
        if recipient && recipient.match('@')
          localResult = recipient.match(re)
          if localResult && localResult[0]
            result.push localResult[0]
    result

  @contentTypeCleanup: (contentType) ->
    return contentType if !contentType
    contentType = contentType.replace(/^(.+?\/.+?)(\b|\s).+?$/, '$1')
    contentType

  @getRecipientArticle: (ticket, article, article_created_by, type, email_addresses = [], all) ->

    # empty form
    articleNew = {
      to:          ''
      cc:          ''
      body:        ''
      in_reply_to: ''
    }

    if article.message_id
      articleNew.in_reply_to = article.message_id

    if type.name is 'phone'

      # inbound call
      if article.sender.name is 'Agent'
        if article.to
          articleNew.to = article.to

      # outbound call
      else if article.to
        articleNew.to = article.to

      # if sender is customer but in article.from is no email, try to get
      # customers email via customer user
      if (articleNew.to && !articleNew.to.match(/@/)) || !articleNew.to
        articleNew.to = ticket.customer.email

      return articleNew

    if type.name is 'email' || type.name is 'web'
      localEmailAddresses = []
      for address in email_addresses
        if address && !_.isEmpty(address.email)
          localEmailAddresses.push address.email.toString().toLowerCase()

      isLocalAddress = (address) ->
        return false if _.isEmpty(address)
        _.contains(localEmailAddresses, address.toString().toLowerCase())

      article_created_by_email = undefined
      if article_created_by && article_created_by.email
        article_created_by_email = article_created_by.email.toLowerCase()

      # check if article sender is local
      senderIsLocal = false
      if !_.isEmpty(article.from)
        senders = App.Utils.parseAddressListLocal(article.from)
        if senders
          for sender in senders
            if sender && sender.match('@')
              senderIsLocal = isLocalAddress(sender)

      # check if article recipient is local
      recipientIsLocal = false
      if !_.isEmpty(article.to)
        recipients = App.Utils.parseAddressListLocal(article.to)
        if recipients && recipients[0]
          for localRecipient in recipients
            recipientIsLocal = isLocalAddress(localRecipient)
            break if recipientIsLocal is true

      # sender is local
      if senderIsLocal
        articleNew.to = article.to

      # sender is agent - sent via system
      else if article.sender.name is 'Agent' && article_created_by_email && article.from && article.from.toString().toLowerCase().match(article_created_by_email) && !recipientIsLocal
        articleNew.to = article.to

      # sender was regular customer
      else
        if article.reply_to
          articleNew.to = article.reply_to
        else
          articleNew.to = article.from

        # if sender is customer but in article.from is no email, try to get
        # customers email via customer user
        if articleNew.to && !articleNew.to.match(/@/)
          articleNew.to = article.created_by.email

      # filter for uniq recipients
      recipientAddresses = {}
      addAddresses = (addressLine, line) ->
        lineNew = ''
        recipients = App.Utils.parseAddressListLocal(addressLine)

        if !_.isEmpty(recipients)
          for recipient in recipients
            if !_.isEmpty(recipient)
              localRecipientAddress = recipient.toString().toLowerCase()

              # check if address is not local
              if !isLocalAddress(localRecipientAddress)

                # filter for uniq recipients
                if !recipientAddresses[localRecipientAddress]
                  recipientAddresses[localRecipientAddress] = true

                  # add recipient
                  if lineNew
                    lineNew = lineNew + ', '
                  lineNew = lineNew + localRecipientAddress

        lineNew
        if !_.isEmpty(line)
          if !_.isEmpty(lineNew)
            lineNew += ', '
          lineNew += line
        lineNew

      if articleNew.to
        articleNew.to = addAddresses(articleNew.to)

      if all
        if article.from
          articleNew.to = addAddresses(article.from, articleNew.to)
        if article.to
          articleNew.to = addAddresses(article.to, articleNew.to)
        if article.cc
          articleNew.cc = addAddresses(article.cc, articleNew.cc)

    articleNew

  # apply email token field with autocompletion
  @tokaniceEmails: (selector) ->
    source = "#{App.Config.get('api_path')}/users/search"
    a = ->
      $(selector).tokenfield(
        createTokensOnBlur: true
        autocomplete: {
          source: source
          minLength: 2
        },
      ).on('tokenfield:createtoken', (e) ->
        if !e.attrs.value.match(/@/) || e.attrs.value.match(/\s/)
          e.preventDefault()
          return false
        e.attrs.label = e.attrs.value
        true
      )
    App.Delay.set(a, 500, undefined, 'tags')

  @htmlImage2DataUrl: (html) ->
    return html if !html
    return html if !html.match(/<img/i)
    html = @_checkTypeOf("<div>#{html}</div>")

    html.find('img').each( (index) ->
      src = $(@).attr('src')
      if !src.match(/^data:/i)
        base64 = App.Utils._htmlImage2DataUrl(@)
        $(@).attr('src', base64)
    )
    html.get(0).innerHTML

  @_htmlImage2DataUrl: (img) ->
    canvas = document.createElement('canvas')
    canvas.width = img.width
    canvas.height = img.height
    ctx = canvas.getContext('2d')
    ctx.drawImage(img, 0, 0)
    canvas.toDataURL('image/png')
