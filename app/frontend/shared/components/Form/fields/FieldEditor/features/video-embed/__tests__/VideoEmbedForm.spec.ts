// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import Document from '@tiptap/extension-document'
import Paragraph from '@tiptap/extension-paragraph'
import Text from '@tiptap/extension-text'
import { Editor } from '@tiptap/vue-3'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import VideoEmbed from '#shared/components/Form/fields/FieldEditor/extensions/VideoEmbed.ts'
import VideoEmbedForm from '#shared/components/Form/fields/FieldEditor/features/video-embed/VideoEmbedForm.vue'

// The form closes itself through the extension's command, so the editor it is handed has to carry
//   the extension - the same way it does in the app.
const renderEditor = (content = '<p></p>') =>
  new Editor({ extensions: [Document, Paragraph, Text, VideoEmbed], content })

const renderForm = (editor: Editor) =>
  renderComponent(VideoEmbedForm, {
    props: { editor },
    form: true,
    store: true,
  })

const submitUrl = async (
  view: ReturnType<typeof renderForm>,
  url: string,
  submit = 'Embed video',
) => {
  await view.events.type(view.getByLabelText('Video URL'), url)
  await view.events.click(view.getByRole('button', { name: submit }))
}

describe('VideoEmbedForm', () => {
  beforeEach(() => {
    mockApplicationConfig({
      kb_self_hosted_video_servers: [
        { name: 'Example Media', host: 'media.example.com' },
        { name: 'Example Video', host: 'video.example.com' },
      ],
    })
  })

  it('inserts the marker of a built-in provider', async () => {
    const editor = renderEditor()

    const view = renderForm(editor)

    await submitUrl(view, 'https://www.youtube.com/watch?v=vTTzwJsHpU8')

    // The empty row the caret was in is the video's to take, rather than being left standing.
    expect(editor.getHTML()).toBe('<p>( widget: video, provider: youtube, id: vTTzwJsHpU8 )</p>')
  })

  it('inserts the marker of a self-hosted provider, carrying its host', async () => {
    const editor = renderEditor()

    const view = renderForm(editor)

    await submitUrl(view, 'https://video.example.com/w/mtHxbyC2Bd4Qd8xkYRZ8AJ')

    expect(editor.getText()).toBe(
      '( widget: video, provider: peertube, host: video.example.com, id: mtHxbyC2Bd4Qd8xkYRZ8AJ )',
    )
  })

  it('inserts the marker as plain text in a paragraph of its own', async () => {
    const editor = renderEditor('<p>Watch this:</p>')

    editor.commands.setTextSelection(editor.state.doc.content.size - 1)

    const view = renderForm(editor)

    await submitUrl(view, 'https://vimeo.com/347119375')

    // Plain text, never a node: the server-side regex works on the raw body string.
    expect(editor.getHTML()).toBe(
      '<p>Watch this:</p><p>( widget: video, provider: vimeo, id: 347119375 )</p>',
    )
  })

  it('puts the video in a row of its own, rather than into the row the caret is in', async () => {
    const editor = renderEditor('<p>Watch this:</p>')

    // Mid-text, where inserting at the caret would have joined the video to the row's own words.
    editor.commands.setTextSelection(6)

    const view = renderForm(editor)

    await submitUrl(view, 'https://vimeo.com/347119375')

    expect(editor.getHTML()).toBe(
      '<p>Watch this:</p><p>( widget: video, provider: vimeo, id: 347119375 )</p>',
    )
  })

  it('puts no second video into a row that already holds one', async () => {
    const stored = '( widget: video, provider: youtube, id: vTTzwJsHpU8 )'

    const editor = renderEditor(`<p>${stored} and more</p>`)

    // In the words beside the stored video rather than in the video itself, so that the form is
    //   embedding a video rather than replacing one — a row of a legacy body, the only way to one.
    editor.commands.setTextSelection(2 + stored.length)

    const view = renderForm(editor)

    await submitUrl(view, 'https://vimeo.com/347119375')

    // A row holds one video and nothing else, so the second one goes below the first.
    expect(editor.getHTML()).toBe(
      `<p>${stored} and more</p><p>( widget: video, provider: vimeo, id: 347119375 )</p>`,
    )
  })

  describe('with the caret in a video that is already there', () => {
    const marker = '( widget: video, provider: youtube, id: vTTzwJsHpU8 )'

    const renderFormOverVideo = () => {
      const editor = renderEditor(`<p>${marker}</p>`)

      editor.commands.setTextSelection(10)

      return { editor, view: renderForm(editor) }
    }

    it('offers to embed a video, like anywhere else', () => {
      const { view } = renderFormOverVideo()

      // A video that is already there is never edited from here: it is removed from its own chip,
      //   and a new one embedded in its place.
      expect(view.getByRole('button', { name: 'Embed video' })).toBeInTheDocument()
      expect(view.queryByRole('button', { name: 'Replace video' })).not.toBeInTheDocument()
    })

    it('embeds the new video below it, rather than over it', async () => {
      const { editor, view } = renderFormOverVideo()

      await submitUrl(view, 'https://vimeo.com/347119375')

      expect(editor.getHTML()).toBe(
        `<p>${marker}</p><p>( widget: video, provider: vimeo, id: 347119375 )</p>`,
      )
    })
  })

  it("offers no removal, which is the chip's own to offer", () => {
    const view = renderForm(renderEditor())

    expect(view.queryByRole('button', { name: 'Remove video' })).not.toBeInTheDocument()
  })

  it('embeds the video at the end of the document when there is no caret in a row', async () => {
    const editor = renderEditor('<p>Watch this:</p>')

    // A selection of the whole document, which sits in no row of its own.
    editor.commands.selectAll()

    const view = renderForm(editor)

    await submitUrl(view, 'https://vimeo.com/347119375')

    expect(editor.getHTML()).toBe(
      '<p>Watch this:</p><p>( widget: video, provider: vimeo, id: 347119375 )</p>',
    )
  })

  it('refuses a URL that is no video URL', async () => {
    const editor = renderEditor()

    const view = renderForm(editor)

    await submitUrl(view, 'https://example.com/some/page')

    expect(await view.findByText('Invalid video URL')).toBeInTheDocument()
    expect(editor.getText()).toBe('')
  })

  it('refuses a self-hosted URL whose host is not an allowed server', async () => {
    const editor = renderEditor()

    const view = renderForm(editor)

    await submitUrl(view, 'https://unknown.example.org/w/mtHxbyC2Bd4Qd8xkYRZ8AJ')

    expect(
      await view.findByText(
        'Video server not allowed. Please add to the list of allowed video servers.',
      ),
    ).toBeInTheDocument()
    expect(editor.getText()).toBe('')
  })

  it('lists the accepted providers', () => {
    const view = renderForm(renderEditor())

    // The built-in providers first, then every allowed server by name, sorted.
    expect(view.getByText('Youtube, Vimeo, Example Media, Example Video')).toBeInTheDocument()
  })
})
