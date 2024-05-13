module.exports = class DetectTranslatableString

  # coffeelint: disable=detect_translatable_string
  rule:
    name: 'detect_translatable_string'
    level: 'ignore'
    message: 'The following string looks like it should be marked as translatable via __(...)'
    description: '''
      '''

  constructor: ->
    @callTokens = []

  tokens: ['STRING', 'CALL_START', 'CALL_END']

  lintToken: (token, tokenApi) ->
    [type, tokenValue] = token

    if type in ['CALL_START', 'CALL_END']
      @trackCall token, tokenApi
      return

    return false if @isInIgnoredMethod()

    return @lintString(token, tokenApi)

  lintString: (token, tokenApi) ->
    [type, tokenValue] = token

    # Remove quotes.
    string = tokenValue[1..-2]

    # Ignore strings with less than two words.
    return false if string.split(' ').length < 2

    # Ignore strings that are being used as exception; unlike Ruby exceptions, these should not reach the user.
    return false if tokenApi.peek(-3)[1] == 'throw'
    return false if tokenApi.peek(-2)[1] == 'throw'
    return false if tokenApi.peek(-1)[1] == 'throw'

    # Ignore strings that are being used for comparison
    return false if tokenApi.peek(-1)[1] == '=='

    # String interpolation is handled via concatenation, ignore such strings.
    return false if tokenApi.peek(1)[1] == '+'
    return false if tokenApi.peek(2)[1] == '+'

    BLOCKLIST = [
      # Only look at strings starting with upper case letters
      /^[^A-Z]/,
      # # Ignore strings starting with three upper case letters like SELECT, POST etc.
      # /^[A-Z]{3}/,
    ]

    return false if BLOCKLIST.some (entry) ->
      #console.log([string, entry, string.match(entry), token, tokenApi.peek(-1), tokenApi.peek(1)])
      string.match(entry)

    # console.log(tokenApi.peek(-3))
    # console.log(tokenApi.peek(-2))
    # console.log(tokenApi.peek(-1))
    # console.log(token)

    return { context: "Found: #{token[1]}" }

  ignoredMethods: {
    '__': true,
    'log': true,
    'T': true,
    'controllerBind': true,
    'debug': true,  # App.Log.debug
    'error': true,  # App.Log.error
    'set': true,  # App.Config.set
    'translateInline': true,
    'translateContent': true,
    'translatePlain': true,
  }

  isInIgnoredMethod: ->
    #console.log(@callTokens)
    for t in @callTokens
      return true if t.isIgnoredMethod
    return false

  trackCall: (token, tokenApi) ->
    if token[0] is 'CALL_START'
      p = tokenApi.peek(-1)
      token.isIgnoredMethod = p and @ignoredMethods[p[1]]
      @callTokens.push(token)
    else
      @callTokens.pop()
    return null
