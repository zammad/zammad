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

QUnit.test('kb reader video marker rendering', assert => {
  var klass = App.KnowledgeBaseReaderController;

  App.Config.set('kb_self_hosted_video_servers', [{host: 'video.example.com', name: 'PeerTube'}])

  var html = klass.prepareVideos('<p>intro</p>( widget: video, provider: youtube, id: vTTzwJsHpU8 )<p>outro</p>')

  assert.ok(html.includes("src='https://www.youtube.com/embed/vTTzwJsHpU8'"), 'renders a YouTube embed')
  assert.ok(html.includes('<p>intro</p>') && html.includes('<p>outro</p>'), 'keeps the surrounding content')

  html = klass.prepareVideos('( widget: video, provider: vimeo, id: 358296442 )')

  assert.ok(html.includes("src='https://player.vimeo.com/video/358296442'"), 'renders a Vimeo embed')

  html = klass.prepareVideos('( widget: video, provider: peertube, host: video.example.com, id: uuid-1 )')

  assert.ok(html.includes("src='https://video.example.com/videos/embed/uuid-1'"), 'renders an allow-listed self-hosted embed')

  html = klass.prepareVideos('( widget: video, provider: peertube, host: evil.example.com, id: uuid-1 )')

  assert.equal(html, '', 'renders nothing for a self-hosted host missing from the allow-list')

  App.Config.set('kb_self_hosted_video_servers', [{host: 'videos.example.com:8080', name: 'PeerTube'}])

  html = klass.prepareVideos('( widget: video, provider: peertube, host: videos.example.com:8080, id: uuid-1 )')

  assert.ok(html.includes("src='https://videos.example.com:8080/videos/embed/uuid-1'"), 'keeps an explicit port of an allow-listed host')

  var evilHost = "evil.example.com:80/x' onmouseover='doevil"

  App.Config.set('kb_self_hosted_video_servers', [{host: evilHost, name: 'Evil'}])

  html = klass.prepareVideos("( widget: video, provider: peertube, host: " + evilHost + ", id: uuid-1 )")

  assert.notOk(html.includes("onmouseover='"), 'escapes a breakout attempt in a host that also contains a colon')

  App.Config.set('kb_self_hosted_video_servers', [{host: 'video.example.com', name: 'PeerTube'}])

  html = klass.prepareVideos('( widget: video, provider: mediacms, id: f9xqzbbJE )')

  assert.equal(html, '', 'renders nothing for a self-hosted provider without a host')

  App.Config.set('kb_self_hosted_video_servers', [{name: 'Entry without host'}])

  html = klass.prepareVideos('( widget: video, provider: peertube, id: uuid-1 )')

  assert.equal(html, '', 'does not match a hostless marker against a malformed allow-list entry')

  App.Config.set('kb_self_hosted_video_servers', [{host: 'video.example.com', name: 'PeerTube'}])

  html = klass.prepareVideos('( widget: video, provider: dailymotion, id: x )')

  assert.equal(html, '', 'renders nothing for an unknown provider')

  html = klass.prepareVideos('( widget: video, provider: youtube )')

  assert.ok(html.includes("id='youtube'"), 'falls back to an empty id for a marker without an id key')

  html = klass.prepareVideos("( widget: video, provider: youtube, id: a' srcdoc='<img src=x onerror=doevil> )")

  assert.notOk(html.includes("srcdoc='"), 'escapes an attribute breakout attempt in the id')
  assert.notOk(html.includes('<img'), 'does not emit injected markup')
})
