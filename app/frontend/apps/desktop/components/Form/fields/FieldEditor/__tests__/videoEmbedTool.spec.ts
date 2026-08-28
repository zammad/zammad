// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import Document from '@tiptap/extension-document'
import Paragraph from '@tiptap/extension-paragraph'
import Text from '@tiptap/extension-text'
import { Editor } from '@tiptap/vue-3'

import { renderComponent } from '#tests/support/components/index.ts'

import VideoEmbed from '#shared/components/Form/fields/FieldEditor/extensions/VideoEmbed.ts'

import FieldEditorActionBar from '#desktop/components/Form/fields/FieldEditor/FieldEditorActionBar.vue'

// The action bar spec next door mocks TipTap away, so what the tool does with a real document in
//   front of it is asked here instead.
const marker = '( widget: video, provider: youtube, id: vTTzwJsHpU8 )'

const renderEditor = () =>
  new Editor({
    extensions: [Document, Paragraph, Text, VideoEmbed],
    content: `<p>Watch ${marker} for more.</p>`,
  })

const renderToolbar = (editor: Editor) =>
  renderComponent(FieldEditorActionBar, {
    props: {
      editor,
      contentType: 'text/html',
      visible: true,
      disabledExtensions: [],
    },
    form: true,
    router: true,
    store: true,
    dialog: true,
  })

describe('video embed tool', () => {
  it.each([
    ['in a stored video', 10],
    ['outside a stored video', 1],
  ])('is not highlighted while the caret sits %s', (_, position) => {
    const editor = renderEditor()

    editor.commands.setTextSelection(position)

    const view = renderToolbar(editor)

    // The tool embeds a video and never edits one that is already there, so there is no state of
    //   the document it stands for.
    expect(view.getByLabelText('Embed video')).toHaveAttribute('aria-pressed', 'false')

    editor.destroy()
  })
})
