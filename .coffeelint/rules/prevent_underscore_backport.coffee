module.exports = class PreventUnderscoreBackport

  rule:
    name: 'prevent_underscore_backport'
    level: 'error'
    message: 'The method __(...) is not available in current stable'
    description: '''
      '''

  constructor: ->
    @callTokens = []

  tokens: ['CALL_START']

  lintToken: (token, tokenApi) ->
    [type, tokenValue] = token

    p = tokenApi.peek(-1)
    if p[1] == '__'
      return { }
