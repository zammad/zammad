class App.CodeEditor extends App.Controller
  elements:
    '.js-codeEditor': 'textarea'

  events:
    'shown.bs.collapse': 'onCollapseExpand'

  constructor: ->
    super

    @render()

  render: ->
    item = $( App.view('generic/code_editor')( attribute: @attribute ) )

    if @attribute.collapsible
      collapseClasses= 'panel-collapse collapse'
      if !_.isEmpty(@attribute.value)
        collapseClasses += ' in'
        collapseExpanded = true
      item = $('<div id="collapse-' + @attribute.id + '" class="' + collapseClasses + '">').append(item)

    # Initialize CodeMirror editor in delayed fashion, but only if it's not initially collapsed.
    #   Otherwise, it will be initialized the first time collapse has been expanded.
    if not @attribute.collapsible or collapseExpanded
      App.Delay.set(@initEditor, 300, undefined, 'init_code_editor')

    @html item

  element: =>
    @el

  regTrigger: ->
    new RegExp('(?<=::|#\{)([a-z0-9_.\s]*)(\}?)', 'g')

  renderHints: (cursor, line, resolve) =>
    hints = null
    matches = Array.from(line.matchAll(@regTrigger()))

    for match in matches
      start = match.index - 2
      end   = start + 2 + match[0].length

      # Skip group if the cursor is not within it.
      continue if cursor.ch < start or cursor.ch > end

      altTrigger = true if match[2].length

      # Extract search term from the input.
      term = match[1].trim().toLowerCase()

      break

    if term is undefined
      resolve(hints)
      return

    reg     = new RegExp(escapeRegExp(term), 'i')
    regFull = new RegExp('\\b' + escapeRegExp(term) + '\\b', 'i')

    matchItemWithRegExp = (item, regex) ->
      (item.name and item.name.match(regex)) or (item.keywords and item.keywords.match(regex))

    compareItem = (a, b) ->
      if a.name < b.name
        return 1
      if a.name > b.name
        return -1
      0

    # Filter autocomplete options based on the current term.
    #   Try to match both partial and literal matches.
    result     = _.filter(@replacements, (item) -> matchItemWithRegExp(item, reg) and not matchItemWithRegExp(item, regFull))
    resultFull = _.filter(@replacements, (item) -> matchItemWithRegExp(item, regFull))

    result.sort(compareItem)

    # If there were literal matches, append them to the list of results.
    if resultFull.length
      resultFull.sort(compareItem)
      result = result.concat(resultFull)

    # Don't show the dropdown if:
    #   - there were no matches
    #   - there was only one, literal match and the user has entered it via `#{...}` trigger
    if not result.length or (altTrigger and result.length is 1 and result[0].text is "\#{#{term}}")
      resolve(hints)
      return

    hints =
      list: result
      from: CodeMirror.Pos(cursor.line, start)
      to: CodeMirror.Pos(cursor.line, end)

    resolve(hints)

  transformReplacements: (replacements) ->
    _.flatten(
      _.map(
        replacements,
        (children, parent) ->
          _.map(
            children,
            (child) ->
              text: "\#{#{parent}.#{child}}"
              name: "#{parent}.#{child}"
              keywords: "#{parent}.#{child}"
              render: (el, self, data) ->
                text = $('<kbd />').append(data.text)
                $(el)
                  .append(data.name)
                  .append(text)
         )
      )
    )

  fetchReplacements: (cursor, line, resolve) =>
    if @replacements
      @renderHints(cursor, line, resolve)
      return

    params = @formParam($(@el).parents('form'))
    pre_defined_webhook_type = params['pre_defined_webhook_type'] || ''

    url = "#{@apiPath}/webhooks/payload/replacements"
    if pre_defined_webhook_type
      url += "?pre_defined_webhook_type=#{pre_defined_webhook_type}"

    @ajax(
      id:    'webhooks_replacements'
      type:  'GET'
      url:   url
      processData: true
      success: (data, status, xhr) =>
        @replacements = @transformReplacements(data)
        @renderHints(cursor, line, resolve)
    )

  hintOptions: =>
    options =
      completeSingle: false

    if !@attribute.noHints
      options.hint = (cm, option) =>
        new Promise((resolve) =>
          cursor = cm.getCursor()
          line = cm.getLine(cursor.line)

          # Resolve early, if there was no trigger detected on the current line.
          if not @regTrigger().test(line)
            resolve(null)
            return

          @fetchReplacements(cursor, line, resolve)
        )

    options

  mode: =>
    @attribute.mode or 'json'

  editorOptions: =>
    autoCloseBrackets: true
    autofocus: @attribute.autofocus
    gutters: if _.isUndefined(@attribute.lineNumbers) or @attribute.lineNumbers then ['CodeMirror-lint-markers'] else [],
    hintOptions: @hintOptions()
    inputStyle: 'contenteditable'
    lineNumbers: if _.isUndefined(@attribute.lineNumbers) then true else @attribute.lineNumbers
    lint:
      skipEmpty: @attribute.null
    matchBrackets: true
    mode: @mode()
    readOnly: @attribute.disabled
    tabSize: 2
    theme: 'zammad'
    value: @textarea.val()

  initEditor: =>
    return if not @textarea.length

    callback = (element) =>
      @textarea.after(element)

    @editor = CodeMirror(callback, @editorOptions())

    @editor.setSize(null, @attribute.height) if @attribute.height

    @editor.on('change', _.throttle(@update, 300))
    @editor.on('cursorActivity', => @editor.showHint())

  update: (editor) =>
    @textarea.val(editor.getValue())

  onCollapseExpand: =>
    return if @editor

    @initEditor()

  release: =>
    if @editor
      @editor.toTextArea()
      @editor = null
