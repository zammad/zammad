# coffeelint: disable=no_unnecessary_double_quotes
class App.Utils
  @mapTagAttributes:
    'FONT': ['color']
    'SPAN': ['style']
    'DIV': ['style']
    'TABLE': ['align', 'bgcolor', 'border', 'cellpadding', 'cellspacing', 'frame', 'rules', 'sortable', 'summary', 'width', 'style']
    'TD': ['abbr', 'align', 'axis', 'colspan', 'headers', 'rowspan', 'valign', 'width', 'style']
    'TH': ['abbr', 'align', 'axis', 'colspan', 'headers', 'rowspan', 'scope', 'sorted', 'valign', 'width', 'style']
    'TR': ['width', 'style']
    'A': ['href', 'hreflang', 'name', 'rel']
    'IMG': ['align', 'alt', 'border', 'height', 'src', 'srcset', 'width', 'style']

  @mapCss:
    'SPAN': [
      'color',
    ]
    'DIV': [
      'color',
    ]
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

  @cssValuesBacklist:
    'DIV': [
      'color:white',
      'color:black',
      'color:#000',
      'color:#000000',
      'color:#fff',
      'color:#ffffff',
      'color:rgb(0,0,0)',
      'color:#585856', # use in UI, ignore it
      'color:rgb(88, 88, 86)' # use in UI, ignore it
      'color:#b3b3b3' # use in UI, ignore it
      'color:rgb(34, 34, 34)' # use in UI, ignore it
    ],
    'SPAN': [
      'color:white',
      'color:black',
      'color:#000',
      'color:#000000',
      'color:#fff',
      'color:#ffffff',
      'color:rgb(0,0,0)',
      'color:#585856', # use in UI, ignore it
      'color:rgb(88, 88, 86)' # use in UI, ignore it
      'color:#b3b3b3' # use in UI, ignore it
      'color:rgb(34, 34, 34)' # use in UI, ignore it
    ],
    'TABLE': [
      'font-size:0',
      'font-size:0px',
      'font-size:0em',
      'font-size:0%',
      'font-size:1px',
      'font-size:1em',
      'font-size:1%',
      'font-size:2',
      'font-size:2px',
      'font-size:2em',
      'font-size:2%',
      'font-size:3',
      'font-size:3px',
      'font-size:3em',
      'font-size:3%',
      'display:none',
      'visibility:hidden',
    ],
    'TH': [
      'font-size:0',
      'font-size:0px',
      'font-size:0em',
      'font-size:0%',
      'font-size:1px',
      'font-size:1em',
      'font-size:1%',
      'font-size:2',
      'font-size:2px',
      'font-size:2em',
      'font-size:2%',
      'font-size:3',
      'font-size:3px',
      'font-size:3em',
      'font-size:3%',
      'display:none',
      'visibility:hidden',
    ],
    'TR': [
      'font-size:0',
      'font-size:0px',
      'font-size:0em',
      'font-size:0%',
      'font-size:1',
      'font-size:1px',
      'font-size:1em',
      'font-size:1%',
      'font-size:2',
      'font-size:2px',
      'font-size:2em',
      'font-size:2%',
      'font-size:3',
      'font-size:3px',
      'font-size:3em',
      'font-size:3%',
      'display:none',
      'visibility:hidden',
    ],
    'TD': [
      'font-size:0',
      'font-size:0px',
      'font-size:0em',
      'font-size:0%',
      'font-size:1px',
      'font-size:1em',
      'font-size:1%',
      'font-size:2',
      'font-size:2px',
      'font-size:2em',
      'font-size:2%',
      'font-size:3',
      'font-size:3px',
      'font-size:3em',
      'font-size:3%',
      'display:none',
      'visibility:hidden',
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
    ascii = ascii.replace(/(\n\r|\r\n|\r)/g, "\n")
    ascii = ascii.replace(/  /g, ' &nbsp;')
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

    # strip out browser-inserted (broken) link
    # (see https://github.com/zammad/zammad/issues/2019)
    @_stripDoubleDomainAnchors(html)

    # remove tags, keep content
    html.find('small, time, form, label').replaceWith( ->
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
    html.find('svg, input, select, button, style, applet, embed, noframes, canvas, script, frame, iframe, meta, link, title, head, fieldset').remove()

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
            if !(@cssValuesBacklist[element.nodeName] && _.contains(@cssValuesBacklist[element.nodeName], local_pear.toLowerCase())) && _.contains(@mapCss[element.nodeName], key)
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

  @_stripDoubleDomainAnchors: (html) ->
    html.find('a').each( ->
      origHref  = $(@).attr('href')
      return if !origHref?

      fixedHref = origHref.replace(/^https?:\/\/.*(?=(https?|#{config.http_type}):\/\/)/, '')
      if origHref != fixedHref then $(@).attr('href', fixedHref)
    )

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

  # messageWithMarker = App.Utils.signatureIdentifyByPlaintext(message, false)
  @signatureIdentifyByPlaintext: (message, test = false, internal = false) ->
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

  @isMicrosoftOffice: (message) ->
    regex = new RegExp('-----(Ursprüngliche Nachricht|Original Message|Mensaje original|Message d\'origine|Messaggio originale|邮件原件|原始郵件)-----')
    message.match(regex)

  # messageWithMarker = App.Utils.signatureIdentifyByHtml(message)
  @signatureIdentifyByHtml: (message) ->
    # use the plaintext fallback method if message is composed by Microsoft Office
    if @isMicrosoftOffice message
      return @signatureIdentifyByPlaintext message

    message_element = $(App.Utils.safeParseHtml(message))
    if message_element.length == 1 && $(message_element[0])?.children()?.length
      message_element[0].innerHTML = @signatureIdentifyByHtmlHelper(message_element[0].innerHTML)
      return message_element[0].outerHTML

    @signatureIdentifyByHtmlHelper(message)

  @signatureIdentifyByHtmlHelper: (message, internal = false) ->
    # blockquotes and signature blocks are considered "dismiss nodes" and their indice will be stored
    dismissNodes = []
    contentNodes = []
    res = []

    isQuoteOrSignature = (el) ->
      el = $(el)
      tag = el.prop("tagName")
      return true if tag is 'BLOCKQUOTE'
      # detect Zammad's own <div data-signature='true'> marker
      return true if tag is 'DIV' && (el.data('signature') || el.prop('class') is 'yahoo_quoted')
      _.some el.children(), (el) -> isQuoteOrSignature el

    try content = $('<div/>').html(message)
    catch e then content = $('<div/>').html('<div>' + message + '</div>')

    # ignore mail structures of case Ticket#1085048
    return message if content.find("div:first span:contains('CAUTION:')").css('color') == 'rgb(156, 101, 0)'

    content.contents().each (index, node) ->
      text = $(node).text()
      if node.nodeType == Node.TEXT_NODE
        # convert text back to HTML as it was before
        res.push $('<div>').text(text).html()
        if text.trim().length
          contentNodes.push index
      else if node.nodeType == Node.ELEMENT_NODE
        res.push node.outerHTML
        if isQuoteOrSignature node
          dismissNodes.push index
        else if text.trim().length
          contentNodes.push index

    # filter out all dismiss nodes smaller than the largest content node
    max_content = _.max contentNodes || 0
    dismissNodes = _.filter dismissNodes, (x) -> x >= max_content

    # return the message unchanged if there are no nodes to dismiss
    return message if !dismissNodes.length

    # insert marker template at the earliest valid location
    markerIndex = _.min dismissNodes
    markerTemplate = '<span class="js-signatureMarker"></span>'

    res.splice(markerIndex, 0, markerTemplate)
    res.join('')

  # textReplaced = App.Utils.replaceTags( template, { user: { firstname: 'Bob', lastname: 'Smith' } } )
  @replaceTags: (template, objects, encodeLink = false) ->
    template = template.replace( /#\{\s{0,2}(.+?)\s{0,2}\}/g, (index, key) ->
      key = key.replace(/<.+?>/g, '')
      levels  = key.split(/\./)
      dataRef = objects
      dataRefLast = undefined
      for level in levels
        if typeof dataRef is 'object' && level of dataRef
          dataRefLast = dataRef
          dataRef = dataRef[level]
        else
          dataRef = ''
          break
      value = undefined

      # if value is a function, execute function
      if typeof dataRef is 'function'
        value = dataRef()

      # if value has content
      else if dataRef isnt undefined && dataRef isnt null && dataRef.toString

        # in case if we have a references object, check what datatype the attribute has
        # and e. g. convert timestamps/dates to browser locale
        if dataRefLast?.constructor?.className
          localClassRef = App[dataRefLast.constructor.className]
          if localClassRef?.attributesGet
            attributes = localClassRef.attributesGet()
            if attributes?[level]
              if attributes[level]['tag'] is 'datetime'
                value = App.i18n.translateTimestamp(dataRef)
              else if attributes[level]['tag'] is 'date'
                value = App.i18n.translateDate(dataRef)

        # as fallback use value of toString()
        if !value
          value = dataRef.toString()
      else
        value = ''
      value = '-' if value is ''
      value = encodeURIComponent(value) if encodeLink
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
        # fix for issue #2042 - incorrect notification when closing a tab after setting up an object
        # Ignore the diff if both conditions are true:
        # 1. current value is the empty string (no user input yet)
        # 2. no previous value (it's a newly added attribute)
        else if dataNow[dataNowkey] == '' && !dataLast[dataNowkey]?
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

    # remove blockquote from message, check only the unquoted content
    tmp = $('<div>' + message + '</div>')
    tmp.find('blockquote').remove()
    text = tmp.text()

    matchwords = ['Attachment', 'attachment', 'Attached', 'attached', 'Enclosed', 'enclosed', 'Enclosure', 'enclosure']
    for word in matchwords
      # en
      attachmentTranslatedRegExp = new RegExp("\\W#{word}\\W", 'i')
      return word if text.match(attachmentTranslatedRegExp)

      # user locale
      attachmentTranslated = App.i18n.translateContent(word)
      attachmentTranslatedRegExp = new RegExp("\\W#{attachmentTranslated}\\W", 'i')
      return attachmentTranslated if text.match(attachmentTranslatedRegExp)
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

  @fontIcon: (name, font, className = '') ->
    @loadIconFont(font)
    "<i class=\"icon #{className}\" data-font=\"#{font}\">#{String.fromCharCode('0x'+ name)}</i>"

  @loadIconFont: (font) ->
    el = $("[data-icon-font=\"#{font}\"]")
    return if el.length # already loaded

    el = $("<style data-icon-font=\"#{font}\">").appendTo('head')
    woffUrl = "assets/icon-fonts/#{font}.woff"
    css = """
          @font-face {
            font-family: '#{font}';
            src: url('#{woffUrl}');
            font-weight: normal;
            font-style: normal;
          }

          [data-font="#{font}"] {
            font-family: '#{font}';
          }
          """

    el.text css

  @loadIconFontInfo: (font, callback) ->
    $.getJSON "assets/icon-fonts/#{font}.json", (data) -> callback(data.icons)

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

      # the article we are replying to is an outbound call
      if article.sender.name is 'Agent'
        if article.to?.match(/@/)
          articleNew.to = App.Utils.parseAddressListLocal(article.to).join(', ')

      # the article we are replying to is an incoming call
      else if article.from?.match(/@/)
        articleNew.to = App.Utils.parseAddressListLocal(article.from).join(', ')

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
        recipients = App.Utils.parseAddressListLocal(addressLine)

        recipients = recipients.map((r) -> r.toString().toLowerCase())
        recipients = _.reject(recipients, (r) -> _.isEmpty(r))
        recipients = _.reject(recipients, (r) -> isLocalAddress(r))
        recipients = _.reject(recipients, (r) -> recipientAddresses[r])
        recipients = _.each(recipients, (r) -> recipientAddresses[r] = true)

        recipients.push(line) if !_.isEmpty(line)

        # see https://github.com/zammad/zammad/issues/2154
        recipients = recipients.map((a) -> a.replace(/'(\S+@\S+\.\S+)'/, '$1'))

        recipients.join(', ')

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
  @tokanice: (selector, type) ->
    source = "#{App.Config.get('api_path')}/users/search"
    a = ->
      $(selector).tokenfield(
        createTokensOnBlur: true
        autocomplete: {
          source: source
          minLength: 2
        },
      ).on('tokenfield:createtoken', (e) ->
        if type is 'email' && !e.attrs.value.match(/@/) || e.attrs.value.match(/\s/)
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

      # <img src="cid: ..."> or an empty src attribute may mean broken emails (see issue #2305 / #2701)
      return if !src? or src.match(/^(data|cid):/i)

      base64 = App.Utils._htmlImage2DataUrl(@)
      $(@).attr('src', base64)
    )
    html.get(0).innerHTML

  @_htmlImage2DataUrl: (img, params = {}) ->
    canvas = document.createElement('canvas')
    canvas.width = img.width
    canvas.height = img.height
    ctx = canvas.getContext('2d')
    ctx.drawImage(img, 0, 0, img.width, img.height)
    try
      data = canvas.toDataURL('image/png')
      params.success(img, data) if params.success
      return data
    catch e
      App.Log.notice('Utils', "Can\'t insert image from #{img.src}", e)
      params.fail(img) if params.fail
    return

  # convert image urls info data urls in element
  @htmlImage2DataUrlAsyncInline: (html, params = {}) ->
    html.find('img').each( (index) ->
      element = $(@)
      src = element.attr('src')

      # <img src="cid: ..."> or an empty src attribute may mean broken emails (see issue #2305 / #2701)
      return if !src? or src.match(/^(data|cid):/i)
      App.Utils._htmlImage2DataUrlAsync(@,
        success: (img, data) ->
          element.attr('src', data)
          element.css('max-width','100%')
          params.success(element, data) if params.success
        fail: (img) ->
          element.remove()
          params.fail(img) if params.fail
      )
    )

  # works asynchronously to make sure images are loaded before converting to base64
  # output is passed to callback
  @htmlImage2DataUrlAsync: (html, callback) ->
    output = @_checkTypeOf("<div>#{html}</div>")

    # coffeelint: disable=indentation
    elems = output
             .find('img')
             .toArray()
             .filter (elem) -> !elem.src.match(/^(data|cid):/i)
    # coffeelint: enable=indentation

    cacheOrDone = ->
      if (nextElem = elems.pop())
        App.Utils._htmlImage2DataUrlAsync(nextElem,
          success: (img, data) ->
            $(nextElem).attr('src', data)
            cacheOrDone()
          fail: (img) ->
            $(nextElem).remove()
            cacheOrDone()
        )
      else
        callback(output[0].innerHTML)

    cacheOrDone()

  @_htmlImage2DataUrlAsync: (originalImage, params = {}) ->
    imageCache = new Image()
    imageCache.crossOrigin = 'anonymous'
    imageCache.onload = ->
      App.Utils._htmlImage2DataUrl(imageCache, params)
    imageCache.onerror = ->
      App.Log.notice('Utils', "Unable to load image from #{originalImage.src}")
      params.fail(originalImage) if params.fail
    imageCache.src = originalImage.src

  @baseUrl: ->
    fqdn      = App.Config.get('fqdn')
    http_type = App.Config.get('http_type')
    if !fqdn || fqdn is 'zammad.example.com'
      url = window.location.origin
    else
      url = "#{http_type}://#{fqdn}"

  @joinUrlComponents: (array...) ->
    if Array.isArray(array[0])
      array = array[0]

    array
      .filter (elem) ->
        elem?
      .join '/'

  @clipboardHtmlIsWithText: (html) ->
    if !html
      return false

    parsedHTML = jQuery(jQuery.parseHTML(html))

    if !parsedHTML || !parsedHTML.text
      return false

    if parsedHTML.text().trim().length is 0
      return false

    true

  @clipboardHtmlInsertPreperation: (htmlRaw, options) ->
    if options.mode is 'textonly'
      if !options.multiline
        html = App.Utils.htmlRemoveTags(htmlRaw)
      else
        html = App.Utils.htmlRemoveRichtext(htmlRaw)
    else
      html = App.Utils.htmlCleanup(htmlRaw)

    htmlString = html.html()

    if !htmlString && html && html.text && html.text()
      htmlString = App.Utils.text2html(html.text())

    # as fallback, get text from htmlRaw
    if !htmlString || htmlString == ''
      parsedHTML = jQuery(jQuery.parseHTML(htmlRaw))
      if parsedHTML
        text = parsedHTML.text().trim()

      if text
        htmlString = App.Utils.text2html(text)

    htmlString

  # Parses HTML text to DOM tree
  # jQuery's parseHTML sometimes fail when element does not have a single root element
  # in that case, fall back to fake root element and try again
  @safeParseHtml: (input) ->
    try $.parseHTML(input)
    catch e then $.parseHTML('<div>' + input + '</div>')[0].childNodes
