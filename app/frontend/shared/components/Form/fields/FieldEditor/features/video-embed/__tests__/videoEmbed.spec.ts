// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import Document from '@tiptap/extension-document'
import Paragraph from '@tiptap/extension-paragraph'
import Text from '@tiptap/extension-text'
import { Editor } from '@tiptap/vue-3'

import {
  detectVideo,
  newVideoRowAt,
  parseVideoWidgetMarker,
  videoMarkerRanges,
  videoServerAllowed,
  videoWidgetMarker,
} from '#shared/components/Form/fields/FieldEditor/features/video-embed/videoEmbed.ts'

describe('detectVideo', () => {
  it.each([
    ['https://www.youtube.com/watch?v=vTTzwJsHpU8', 'youtube', 'vTTzwJsHpU8'],
    ['https://youtu.be/vTTzwJsHpU8', 'youtube', 'vTTzwJsHpU8'],
    ['https://www.youtube.com/embed/vTTzwJsHpU8', 'youtube', 'vTTzwJsHpU8'],
    ['https://vimeo.com/347119375', 'vimeo', '347119375'],
  ])('detects %s', (url, provider, id) => {
    expect(detectVideo(url)).toEqual({ provider, id })
  })

  it.each([
    ['https://video.example.com/w/mtHxbyC2Bd4Qd8xkYRZ8AJ', 'peertube', 'mtHxbyC2Bd4Qd8xkYRZ8AJ'],
    [
      'https://video.example.com/videos/watch/mtHxbyC2Bd4Qd8xkYRZ8AJ',
      'peertube',
      'mtHxbyC2Bd4Qd8xkYRZ8AJ',
    ],
    ['https://media.example.com/view?m=Ai8hFnEt2', 'mediacms', 'Ai8hFnEt2'],
  ])('detects self-hosted %s', (url, provider, id) => {
    expect(detectVideo(url)).toEqual({
      provider,
      id,
      host: new URL(url).host,
    })
  })

  it('detects a URL pasted without its scheme', () => {
    expect(detectVideo('video.example.com/w/mtHxbyC2Bd4Qd8xkYRZ8AJ')).toEqual({
      provider: 'peertube',
      id: 'mtHxbyC2Bd4Qd8xkYRZ8AJ',
      host: 'video.example.com',
    })
  })

  it('detects a self-hosted URL whose host is not an allowed server', () => {
    // The host is not looked at here - whether it is allowed is a separate question, with its own
    //   error message.
    const video = detectVideo('https://unknown.example.org/w/mtHxbyC2Bd4Qd8xkYRZ8AJ')

    expect(video).toEqual({
      provider: 'peertube',
      id: 'mtHxbyC2Bd4Qd8xkYRZ8AJ',
      host: 'unknown.example.org',
    })

    expect(videoServerAllowed(video!.host!, [{ name: 'Example', host: 'video.example.com' }])).toBe(
      false,
    )
  })

  it.each([
    ['an unrecognised URL', 'https://example.com/some/page'],
    ['an empty string', ''],
    ['no input at all', undefined],
  ])('detects nothing in %s', (_, url) => {
    expect(detectVideo(url)).toBeUndefined()
  })
})

describe('videoWidgetMarker', () => {
  it('writes the marker of a built-in provider', () => {
    expect(videoWidgetMarker({ provider: 'youtube', id: 'vTTzwJsHpU8' })).toBe(
      '( widget: video, provider: youtube, id: vTTzwJsHpU8 )',
    )
  })

  it('writes the marker of a self-hosted provider, carrying its host', () => {
    expect(
      videoWidgetMarker({
        provider: 'peertube',
        id: 'mtHxbyC2Bd4Qd8xkYRZ8AJ',
        host: 'video.example.com',
      }),
    ).toBe(
      '( widget: video, provider: peertube, host: video.example.com, id: mtHxbyC2Bd4Qd8xkYRZ8AJ )',
    )
  })
})

describe('parseVideoWidgetMarker', () => {
  it('parses a built-in provider back out of its marker', () => {
    expect(parseVideoWidgetMarker('( widget: video, provider: youtube, id: vTTzwJsHpU8 )')).toEqual(
      {
        provider: 'youtube',
        id: 'vTTzwJsHpU8',
      },
    )
  })

  it('parses a self-hosted provider back out of its marker', () => {
    expect(
      parseVideoWidgetMarker(
        '( widget: video, provider: peertube, host: video.example.com, id: mtHxbyC2Bd4Qd8xkYRZ8AJ )',
      ),
    ).toEqual({
      provider: 'peertube',
      id: 'mtHxbyC2Bd4Qd8xkYRZ8AJ',
      host: 'video.example.com',
    })
  })

  it.each([
    ['a built-in provider', { provider: 'youtube' as const, id: 'vTTzwJsHpU8' }],
    [
      'a self-hosted provider',
      { provider: 'peertube' as const, id: 'uuid-1', host: 'video.example.com' },
    ],
  ])('round-trips what the tool writes for %s', (_, video) => {
    expect(parseVideoWidgetMarker(videoWidgetMarker(video))).toEqual(video)
  })

  it('parses a marker written without the spacing the tool uses', () => {
    expect(parseVideoWidgetMarker('(widget:video,provider:vimeo,id:347119375)')).toEqual({
      provider: 'vimeo',
      id: '347119375',
    })
  })

  it.each([
    ['an unknown provider', '( widget: video, provider: dailymotion, id: x )'],
    ['no provider at all', '( widget: video, id: x )'],
    ['no id', '( widget: video, provider: youtube )'],
    ['an empty id', '( widget: video, provider: youtube, id: )'],
    ['a self-hosted provider without its host', '( widget: video, provider: peertube, id: x )'],
    ['another kind of widget', '( widget: gallery, provider: youtube, id: x )'],
    // A provider is looked up in an object, whose own keys are the providers there are. Every
    //   object also answers for the names it inherits, and none of those is a provider.
    [
      'a provider named after an inherited one',
      '( widget: video, provider: constructor, host: video.example.com, id: x )',
    ],
    [
      'a provider named after an inherited method',
      '( widget: video, provider: toString, host: video.example.com, id: x )',
    ],
  ])('parses nothing out of a marker with %s', (_, marker) => {
    // Whatever the server would not expand either is left alone rather than presented as a video.
    expect(parseVideoWidgetMarker(marker)).toBeUndefined()
  })
})

describe('videoMarkerRanges', () => {
  const marker = '( widget: video, provider: youtube, id: vTTzwJsHpU8 )'

  const renderEditor = (content: string) =>
    new Editor({ extensions: [Document, Paragraph, Text], content })

  it('finds every marker in the document', () => {
    const editor = renderEditor(`<p>Watch ${marker}</p><p>and ${marker} too</p>`)

    expect(videoMarkerRanges(editor.state.doc)).toEqual([
      // "Watch " into the first paragraph, and "and " into the second one.
      { from: 7, to: 7 + marker.length, marker },
      { from: 66, to: 66 + marker.length, marker },
    ])

    editor.destroy()
  })

  it('finds both markers of one paragraph', () => {
    const editor = renderEditor(`<p>${marker} ${marker}</p>`)

    expect(videoMarkerRanges(editor.state.doc)).toHaveLength(2)

    editor.destroy()
  })

  it('finds nothing in a document without a marker', () => {
    const editor = renderEditor('<p>Just some text</p>')

    expect(videoMarkerRanges(editor.state.doc)).toEqual([])

    editor.destroy()
  })
})

describe('newVideoRowAt', () => {
  const renderEditor = (content: string) =>
    new Editor({ extensions: [Document, Paragraph, Text], content })

  it('gives an empty row to the video', () => {
    const editor = renderEditor('<p></p>')

    // The whole row, which the video takes rather than being put below it.
    expect(newVideoRowAt(editor)).toEqual({ from: 0, to: 2 })

    editor.destroy()
  })

  it('puts the video under the row the caret is in', () => {
    const editor = renderEditor('<p>Watch this:</p><p>And this.</p>')

    editor.commands.setTextSelection(6)

    // Under the first row rather than in it, whose text the video would otherwise have joined.
    expect(newVideoRowAt(editor)).toBe(13)

    editor.destroy()
  })

  it('puts the video at the end of the document when the caret is in no row', () => {
    const editor = renderEditor('<p>Watch this:</p><p>And this.</p>')

    // A selection of the whole document sits in no row of its own.
    editor.commands.selectAll()

    expect(newVideoRowAt(editor)).toBe(editor.state.doc.content.size)

    editor.destroy()
  })
})
