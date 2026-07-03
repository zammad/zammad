QUnit.test('kb video url parsing and converting to embeding url', assert => {
  var klass = App.UiElement.richtext.additions.RichTextToolPopupVideo;

  var parsed = klass.detectProviderAndId('https://www.youtube.com/watch?v=vTTzwJsHpU8')

  assert.deepEqual(parsed, {provider: 'youtube', id: 'vTTzwJsHpU8'})

  var parsed = klass.detectProviderAndId('https://www.youtube.com/watch?v=vTTzwJsHpU8&other=true')

  assert.deepEqual(parsed, {provider: 'youtube', id: 'vTTzwJsHpU8'})

  var parsed = klass.detectProviderAndId('https://www.youtube.com/watch?v=vTTzwJsHpU8#hashtag')

  assert.deepEqual(parsed, {provider: 'youtube', id: 'vTTzwJsHpU8'})

  var parsed = klass.detectProviderAndId('https://www.youtube.com/watch?v=_EYF1-2uiIg')

  assert.deepEqual(parsed, {provider: 'youtube', id: '_EYF1-2uiIg'})

  var parsed = klass.detectProviderAndId('https://www.youtu.be/vTTzwJsHpU8')

  assert.deepEqual(parsed, {provider: 'youtube', id: 'vTTzwJsHpU8'})

  var parsed = klass.detectProviderAndId('https://www.youtube.com/embed/vTTzwJsHpU8')

  assert.deepEqual(parsed, {provider: 'youtube', id: 'vTTzwJsHpU8'})

  var parsed = klass.detectProviderAndId('https://www.vimeo.com/358296442')

  assert.deepEqual(parsed, {provider: 'vimeo', id: '358296442'})

  var parsed = klass.detectProviderAndId('https://peertube.tv/w/dj9RAeobeciQGNPzJTSsN3')

  App.Config.set('kb_self_hosted_video_servers', [{host: 'peertube.tv', name: 'PeerTube'}])

  assert.deepEqual(parsed, {provider: 'peertube', id: 'dj9RAeobeciQGNPzJTSsN3', host: 'peertube.tv'})

  App.Config.set('kb_self_hosted_video_servers', [{host: 'demo.mediacms.io', name: 'MediaCMS'}])

  var parsed = klass.detectProviderAndId('https://demo.mediacms.io/view?m=f9xqzbbJE')

  assert.deepEqual(parsed, {provider: 'mediacms', id: 'f9xqzbbJE', host: 'demo.mediacms.io'})
})
