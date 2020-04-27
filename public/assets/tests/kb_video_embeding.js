test('kb video url parsing and converting to embeding url', function() {
  var klass = App.UiElement.richtext.additions.RichTextToolPopupVideo;

  var parsed = klass.detectProviderAndId('https://www.youtube.com/watch?v=vTTzwJsHpU8')

  equal(parsed[0], 'youtube')
  equal(parsed[1], 'vTTzwJsHpU8')

  var parsed = klass.detectProviderAndId('https://www.youtube.com/watch?v=vTTzwJsHpU8&other=true')

  equal(parsed[0], 'youtube')
  equal(parsed[1], 'vTTzwJsHpU8')

  var parsed = klass.detectProviderAndId('https://www.youtube.com/watch?v=vTTzwJsHpU8#hashtag')

  equal(parsed[0], 'youtube')
  equal(parsed[1], 'vTTzwJsHpU8')

  var parsed = klass.detectProviderAndId('https://www.youtube.com/watch?v=_EYF1-2uiIg')

  equal(parsed[0], 'youtube')
  equal(parsed[1], '_EYF1-2uiIg')

  var parsed = klass.detectProviderAndId('https://www.youtu.be/vTTzwJsHpU8')

  equal(parsed[0], 'youtube')
  equal(parsed[1], 'vTTzwJsHpU8')

  var parsed = klass.detectProviderAndId('https://www.youtube.com/embed/vTTzwJsHpU8')

  equal(parsed[0], 'youtube')
  equal(parsed[1], 'vTTzwJsHpU8')

  var parsed = klass.detectProviderAndId('https://www.vimeo.com/358296442')

  equal(parsed[0], 'vimeo')
  equal(parsed[1], '358296442')
})
