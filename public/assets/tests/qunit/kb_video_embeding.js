QUnit.test('kb video url parsing and converting to embeding url', assert => {
  var klass = App.UiElement.richtext.additions.RichTextToolPopupVideo;

  var parsed = klass.detectProviderAndId('https://www.youtube.com/watch?v=vTTzwJsHpU8')

  assert.equal(parsed[0], 'youtube')
  assert.equal(parsed[1], 'vTTzwJsHpU8')

  var parsed = klass.detectProviderAndId('https://www.youtube.com/watch?v=vTTzwJsHpU8&other=true')

  assert.equal(parsed[0], 'youtube')
  assert.equal(parsed[1], 'vTTzwJsHpU8')

  var parsed = klass.detectProviderAndId('https://www.youtube.com/watch?v=vTTzwJsHpU8#hashtag')

  assert.equal(parsed[0], 'youtube')
  assert.equal(parsed[1], 'vTTzwJsHpU8')

  var parsed = klass.detectProviderAndId('https://www.youtube.com/watch?v=_EYF1-2uiIg')

  assert.equal(parsed[0], 'youtube')
  assert.equal(parsed[1], '_EYF1-2uiIg')

  var parsed = klass.detectProviderAndId('https://www.youtu.be/vTTzwJsHpU8')

  assert.equal(parsed[0], 'youtube')
  assert.equal(parsed[1], 'vTTzwJsHpU8')

  var parsed = klass.detectProviderAndId('https://www.youtube.com/embed/vTTzwJsHpU8')

  assert.equal(parsed[0], 'youtube')
  assert.equal(parsed[1], 'vTTzwJsHpU8')

  var parsed = klass.detectProviderAndId('https://www.vimeo.com/358296442')

  assert.equal(parsed[0], 'vimeo')
  assert.equal(parsed[1], '358296442')
})
