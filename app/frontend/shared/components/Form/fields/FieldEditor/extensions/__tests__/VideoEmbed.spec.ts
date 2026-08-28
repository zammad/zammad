// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import Document from '@tiptap/extension-document'
import Paragraph from '@tiptap/extension-paragraph'
import Text from '@tiptap/extension-text'
import { Editor } from '@tiptap/vue-3'

import VideoEmbed, {
  VIDEO_CHIP_CLASS,
  VIDEO_MARKER_CLASS,
} from '#shared/components/Form/fields/FieldEditor/extensions/VideoEmbed.ts'
import VideoEmbedForm from '#shared/components/Form/fields/FieldEditor/features/video-embed/VideoEmbedForm.vue'
import { setFloatingPopover } from '#shared/components/Form/fields/FieldEditor/utils.ts'

// The video embed form is a desktop-only affair, and the extension reads the app name when it is
//   loaded, before any of the app initializers a component render would run.
vi.mock('#shared/composables/useAppName.ts', () => ({
  useAppName: () => 'desktop',
  initializeAppName: vi.fn(),
}))

vi.mock('#shared/components/Form/fields/FieldEditor/utils.ts', async (importOriginal) => ({
  ...(await importOriginal<object>()),
  setFloatingPopover: vi.fn(() => ({
    element: document.createElement('div'),
    destroy: vi.fn(),
  })),
}))

const marker = '( widget: video, provider: youtube, id: vTTzwJsHpU8 )'

const renderEditor = (content: string) =>
  new Editor({
    extensions: [Document, Paragraph, Text, VideoEmbed],
    content,
  })

// ProseMirror derives the clicked position from the layout, which jsdom has none of, so the handler
//   the extension registers is invoked for the given position instead.
const clickAt = (editor: Editor, position: number) => {
  editor.commands.setTextSelection(position)

  editor.view.someProp('handleClick', (handleClick) =>
    handleClick(editor.view, position, new MouseEvent('click')),
  )
}

const openedForm = () => vi.mocked(setFloatingPopover).mock.calls.at(-1)?.[0]

const openedFormAnchor = () => vi.mocked(setFloatingPopover).mock.calls.at(-1)?.[3]?.anchor

// Text input, like a click, is a handler the extension registers rather than anything jsdom would
//   produce from a keystroke.
const typeAt = (editor: Editor, position: number, text: string) => {
  editor.commands.setTextSelection(position)

  return !!editor.view.someProp('handleTextInput', (handleTextInput) =>
    // The last argument is the transaction ProseMirror would have applied itself, which the
    //   extension has no use for.
    handleTextInput(editor.view, position, position, text, () => editor.state.tr),
  )
}

const clickRemoveButton = (editor: Editor, chipIndex = 0) => {
  const chip = editor.view.dom.querySelectorAll(`.${VIDEO_CHIP_CLASS}`)[chipIndex]

  chip
    .querySelector(`.${VIDEO_CHIP_CLASS}-remove-button`)!
    .dispatchEvent(new MouseEvent('click', { bubbles: true }))
}

beforeEach(() => {
  vi.mocked(setFloatingPopover).mockClear()
})

describe('VideoEmbed extension', () => {
  describe('stored video chip', () => {
    const decorations = (editor: Editor) =>
      editor.view.dom.querySelectorAll(`.${VIDEO_MARKER_CLASS}`)

    const chips = (editor: Editor) => editor.view.dom.querySelectorAll(`.${VIDEO_CHIP_CLASS}`)

    const captions = (editor: Editor) => editor.view.dom.querySelectorAll('figcaption')

    it('shows a chip naming the service and the video, over a hidden marker', () => {
      const editor = renderEditor(`<p>Watch ${marker} for more.</p>`)

      expect(chips(editor)).toHaveLength(1)
      expect(captions(editor)[0]).toHaveTextContent('YouTube video · vTTzwJsHpU8')

      // The marker itself stays in the document, hidden behind the chip drawn in its place.
      expect(decorations(editor)).toHaveLength(1)
      expect(decorations(editor)[0]).toHaveTextContent(marker)

      editor.destroy()
    })

    it('is a figure of the video it stands for, captioned with what it is called', () => {
      const editor = renderEditor(`<p>${marker}</p>`)

      // The chip stands in for the player the reader gets, and what it is called belongs to it as
      //   a caption rather than as text of the row it sits in.
      expect(chips(editor)[0].tagName).toBe('FIGURE')
      expect(captions(editor)[0].parentElement).toBe(chips(editor)[0])

      editor.destroy()
    })

    it('names the server of a self-hosted video too', () => {
      const editor = renderEditor(
        '<p>( widget: video, provider: peertube, host: video.example.com, id: mtHxbyC2Bd4Qd8xkYRZ8AJ )</p>',
      )

      expect(captions(editor)[0]).toHaveTextContent(
        'PeerTube video · video.example.com · mtHxbyC2Bd4Qd8xkYRZ8AJ',
      )

      editor.destroy()
    })

    it('shows the video icon on the chip', () => {
      const editor = renderEditor(`<p>${marker}</p>`)

      expect(chips(editor)[0].querySelector(`.${VIDEO_CHIP_CLASS}-preview use`)).toHaveAttribute(
        'href',
        '#icon-camera-video',
      )

      editor.destroy()
    })

    it('takes no part in editing the document', () => {
      const editor = renderEditor(`<p>${marker}</p>`)

      expect(chips(editor)[0]).toHaveAttribute('contenteditable', 'false')

      editor.destroy()
    })

    it('shows a chip for every stored video of the document', () => {
      const editor = renderEditor(`<p>${marker}</p><p>Text</p><p>${marker}</p>`)

      expect(chips(editor)).toHaveLength(2)

      editor.destroy()
    })

    it('leaves the document alone', () => {
      const content = `<p>Watch ${marker} for more.</p>`

      const editor = renderEditor(content)

      // A decoration is a view-layer affair: the stored format must not change, since the same body
      //   is read by the server, the public help pages and the legacy stack.
      expect(editor.getHTML()).toBe(content)
      expect(editor.state.doc.textContent).toBe(`Watch ${marker} for more.`)

      editor.destroy()
    })

    it('keeps showing a chip after the document around it changed', () => {
      const editor = renderEditor(`<p>Watch ${marker}</p>`)

      editor.commands.insertContentAt(1, 'Please ')

      expect(chips(editor)).toHaveLength(1)
      expect(editor.getHTML()).toContain(marker)

      editor.destroy()
    })

    it('shows no chip for a marker of an unknown provider', () => {
      const unknown = '( widget: video, provider: dailymotion, id: x )'

      const editor = renderEditor(`<p>${unknown}</p>`)

      // What a body written against a provider that has since been removed looks like: it stays
      //   plain text, the way the server leaves it too.
      expect(chips(editor)).toHaveLength(0)
      expect(decorations(editor)).toHaveLength(0)
      expect(editor.getHTML()).toBe(`<p>${unknown}</p>`)

      editor.destroy()
    })

    it('shows no chip for another kind of widget', () => {
      const editor = renderEditor('<p>( widget: gallery, provider: youtube, id: x )</p>')

      expect(chips(editor)).toHaveLength(0)

      editor.destroy()
    })

    it('does nothing when the chip itself is clicked', () => {
      const editor = renderEditor(`<p>Watch ${marker}</p>`)

      const chip = chips(editor)[0] as HTMLElement

      chip.dispatchEvent(new MouseEvent('click', { bubbles: true }))

      // A video that is already there is removed and embedded anew, and its own button is the only
      //   way to remove it.
      expect(setFloatingPopover).not.toHaveBeenCalled()
      expect(editor.getHTML()).toContain(marker)

      editor.destroy()
    })

    // Elsewhere in this spec a click is the handler the extension registers, called by hand. Here
    //   it is the event itself, because what is under test is whether an event coming out of the
    //   chip reaches ProseMirror at all, which is decided before any handler of ours would run.
    describe('a click as the browser delivers it', () => {
      const attached: HTMLElement[] = []

      afterEach(() => {
        attached.splice(0).forEach((element) => element.remove())
      })

      // In the document, unlike the editors elsewhere in this spec: ProseMirror finishes a click on
      //   the document, which the events of a detached editor never reach.
      const renderAttachedEditor = (content: string) => {
        const element = document.body.appendChild(document.createElement('div'))

        attached.push(element)

        return new Editor({ element, extensions: [Document, Paragraph, Text, VideoEmbed], content })
      }

      // jsdom lays nothing out, so where the click lands is the one thing that has to be stood in
      //   for; the rest of the way is ProseMirror's own.
      const clickOn = (editor: Editor, target: Element) => {
        vi.spyOn(editor.view, 'posAtCoords').mockReturnValue({ pos: 1, inside: -1 })

        for (const type of ['mousedown', 'mouseup']) {
          target.dispatchEvent(new MouseEvent(type, { bubbles: true, button: 0 }))
        }
      }

      const openForm = (editor: Editor) => {
        editor.commands.openVideoEmbedForm()

        return vi.mocked(setFloatingPopover).mock.results.at(-1)!.value
      }

      it('leaves an open form alone when it lands on a chip', () => {
        const editor = renderAttachedEditor(`<p>${marker}</p>`)

        const { destroy } = openForm(editor)

        clickOn(editor, editor.view.dom.querySelector(`.${VIDEO_CHIP_CLASS}`)!)

        // The chip takes no part in editing the document, so ProseMirror is told to keep its hands
        //   off what comes out of it: a click on it is not one of the clicks that close a form.
        expect(destroy).not.toHaveBeenCalled()

        editor.destroy()
      })

      it('closes an open form when it lands anywhere else in the editor', () => {
        const editor = renderAttachedEditor(`<p>${marker}</p>`)

        const { destroy } = openForm(editor)

        // The same click one step outside the chip, which is what tells the test above apart from
        //   one that never reached ProseMirror in the first place.
        clickOn(editor, editor.view.dom.querySelector('p')!)

        expect(destroy).toHaveBeenCalled()

        editor.destroy()
      })
    })

    describe('remove button', () => {
      it('is the only thing the chip offers', () => {
        const editor = renderEditor(`<p>${marker}</p>`)

        const buttons = chips(editor)[0].querySelectorAll('button')

        // A video is never edited in place: it is removed, and a new one embedded in its place.
        expect(buttons).toHaveLength(1)
        expect(buttons[0]).toHaveAttribute('title', 'Remove video')

        editor.destroy()
      })

      it('drops the video it belongs to, without asking', () => {
        const editor = renderEditor(`<p>Watch ${marker} for more.</p>`)

        clickRemoveButton(editor)

        expect(editor.getHTML()).toBe('<p>Watch  for more.</p>')
        expect(chips(editor)).toHaveLength(0)

        editor.destroy()
      })

      it('drops only the video it belongs to', () => {
        const editor = renderEditor(`<p>${marker}</p><p>Second ${marker}</p>`)

        clickRemoveButton(editor, 1)

        expect(editor.getHTML()).toBe(`<p>${marker}</p><p>Second </p>`)

        editor.destroy()
      })

      it('takes an open form down with it', () => {
        const editor = renderEditor(`<p>Watch ${marker}</p>`)

        editor.commands.setTextSelection(10)
        editor.commands.openVideoEmbedForm()

        const { destroy } = vi.mocked(setFloatingPopover).mock.results.at(-1)!.value

        clickRemoveButton(editor)

        expect(destroy).toHaveBeenCalled()

        editor.destroy()
      })
    })
  })

  describe('the caret in the row of a stored video', () => {
    // Where ProseMirror puts the caret in the DOM, which is what decides where the browser draws
    //   it: the same side it asks for when it puts a selection into the document.
    const caretDom = (editor: Editor, position: number) => editor.view.domAtPos(position, -1)

    const markerOf = (editor: Editor) => editor.view.dom.querySelector(`.${VIDEO_MARKER_CLASS}`)!

    it('sits in front of the chip at the start of the row', () => {
      const editor = renderEditor(`<p>${marker}</p>`)

      const { node, offset } = caretDom(editor, 1)

      expect(node).toBe(editor.view.dom.querySelector('p'))
      // Ahead of the chip, which is the first thing in the row.
      expect(offset).toBe(0)
      expect(node.childNodes[offset]).toHaveClass(VIDEO_CHIP_CLASS)

      editor.destroy()
    })

    it('sits right behind the chip at the end of the row', () => {
      const editor = renderEditor(`<p>${marker}</p>`)

      const { node, offset } = caretDom(editor, 1 + marker.length)

      expect(node).toBe(editor.view.dom.querySelector('p'))
      // Behind the empty element that ends the marker. Nothing between it and the chip takes up
      //   any room, so that is where the caret is drawn — not at the far end of the row.
      expect(node.childNodes[offset - 1]).toBe(markerOf(editor).nextSibling)

      editor.destroy()
    })

    it('sits between the text and the chip of a row that holds both', () => {
      const editor = renderEditor(`<p>Watch ${marker} now</p>`)

      const front = caretDom(editor, 7)

      expect(front.node).toBe(markerOf(editor).previousSibling?.previousSibling)
      expect(front.offset).toBe('Watch '.length)

      const end = caretDom(editor, 7 + marker.length)

      expect(end.node.childNodes[end.offset - 1]).toBe(markerOf(editor).nextSibling)

      editor.destroy()
    })

    it.each([
      ['the start', 1],
      ['the end', 1 + marker.length],
    ])('is kept out of the hidden marker at %s of the row', (_, position) => {
      const editor = renderEditor(`<p>${marker}</p>`)

      // A caret in text the browser never laid out is drawn wherever the browser likes, which is
      //   the far end of the row rather than anywhere near the chip.
      expect(caretDom(editor, position).node).not.toBe(markerOf(editor).firstChild)

      editor.destroy()
    })
  })

  describe('keys acting on a whole stored video', () => {
    // `someProp` hands back the first handler's result that is truthy, so an unhandled key comes
    //   back as undefined rather than as false.
    const pressKey = (editor: Editor, key: string, position: number) => {
      editor.commands.setTextSelection(position)

      return !!editor.view.someProp('handleKeyDown', (handleKeyDown) =>
        handleKeyDown(editor.view, new KeyboardEvent('keydown', { key })),
      )
    }

    it.each([
      ['from within it', 'Backspace', 10],
      ['from its end', 'Backspace', 1 + marker.length],
      ['from within it, forwards', 'Delete', 10],
      ['from its start, forwards', 'Delete', 1],
    ])('deletes the whole video %s', (_, key, position) => {
      const editor = renderEditor(`<p>${marker}</p>`)

      expect(pressKey(editor, key, position)).toBe(true)
      expect(editor.getHTML()).toBe('<p></p>')

      editor.destroy()
    })

    it('leaves a backspace before a video to the editor', () => {
      const editor = renderEditor(`<p>Watch ${marker}</p>`)

      // Deleting the space in front of the video is nothing to do with the video.
      expect(pressKey(editor, 'Backspace', 7)).toBe(false)
      expect(editor.getHTML()).toContain(marker)

      editor.destroy()
    })

    it.each([
      ['left over it', 'ArrowLeft', 1 + marker.length, 1],
      ['right over it', 'ArrowRight', 1, 1 + marker.length],
    ])('steps %s rather than through its hidden characters', (_, key, position, expected) => {
      const editor = renderEditor(`<p>${marker}</p>`)

      expect(pressKey(editor, key, position)).toBe(true)
      expect(editor.state.selection.from).toBe(expected)

      editor.destroy()
    })

    it('leaves keys pressed outside a video to the editor', () => {
      const editor = renderEditor('<p>Hello</p>')

      expect(pressKey(editor, 'Backspace', 3)).toBe(false)

      editor.destroy()
    })

    it('leaves keys pressed in a marker that is shown as no video to the editor', () => {
      const unknown = '( widget: video, provider: dailymotion, id: x )'

      const editor = renderEditor(`<p>${unknown}</p>`)

      // Nothing is hidden behind a chip here — the marker is the plain text it looks like, so it
      //   is edited character by character like any other.
      expect(pressKey(editor, 'Backspace', 10)).toBe(false)
      expect(pressKey(editor, 'ArrowLeft', 10)).toBe(false)
      expect(editor.getHTML()).toBe(`<p>${unknown}</p>`)

      editor.destroy()
    })
  })

  it('opens the form next to the caret', () => {
    const editor = renderEditor('<p>Hello</p>')

    editor.commands.openVideoEmbedForm()

    expect(openedForm()).toBe(VideoEmbedForm)
    // Nothing to place it against: there is no video yet, so it hangs off the caret itself.
    expect(openedFormAnchor()).toBeUndefined()

    editor.destroy()
  })

  it('opens the form under the chip of the video the caret sits in', () => {
    const editor = renderEditor(`<p>Watch ${marker}</p>`)

    // What the toolbar tool does, which lights up for a caret in a stored video: it opens the form
    //   without knowing which chip it belongs to.
    editor.commands.setTextSelection(10)
    editor.commands.openVideoEmbedForm()

    // The chip, not the hidden marker, which has no size of its own to be placed against — a form
    //   with nothing to measure ends up in the corner of the screen.
    expect(openedFormAnchor()).toBe(editor.view.dom.querySelector(`.${VIDEO_CHIP_CLASS}`))

    editor.destroy()
  })

  it('opens the form under the chip of that video, not of another one', () => {
    const editor = renderEditor(`<p>${marker}</p><p>${marker}</p>`)

    editor.commands.setTextSelection(editor.state.doc.content.size - 1)
    editor.commands.openVideoEmbedForm()

    expect(openedFormAnchor()).toBe(editor.view.dom.querySelectorAll(`.${VIDEO_CHIP_CLASS}`)[1])

    editor.destroy()
  })

  describe('text typed in the row of a stored video', () => {
    it('starts a row of its own below the video', () => {
      const editor = renderEditor(`<p>${marker}</p>`)

      // Where a click in the empty space of the video's row leaves the caret.
      expect(typeAt(editor, 1 + marker.length, 'Hello')).toBe(true)

      // A row holds one video and nothing else, so the text goes below it instead.
      expect(editor.getHTML()).toBe(`<p>${marker}</p><p>Hello</p>`)

      editor.destroy()
    })

    it('starts a row of its own above the video, for text typed in front of it', () => {
      const editor = renderEditor(`<p>${marker}</p>`)

      expect(typeAt(editor, 1, 'Hello')).toBe(true)
      expect(editor.getHTML()).toBe(`<p>Hello</p><p>${marker}</p>`)

      editor.destroy()
    })

    it('leaves the caret in the row it started above the video', () => {
      const editor = renderEditor(`<p>${marker}</p>`)

      typeAt(editor, 1, 'Hello')

      expect(editor.state.selection.from).toBe(6)

      editor.destroy()
    })

    it('leaves the caret behind what was typed, so that the rest is typed on', () => {
      const editor = renderEditor(`<p>${marker}</p>`)

      typeAt(editor, 1 + marker.length, 'Hello')

      expect(editor.state.selection.from).toBe(editor.state.doc.content.size - 1)
      // The paragraph the text started is no video's, so it takes the rest of the sentence as any
      //   other paragraph would.
      expect(typeAt(editor, editor.state.selection.from, '!')).toBe(false)

      editor.destroy()
    })

    it('keeps the video it was typed beside', () => {
      const editor = renderEditor(`<p>Watch ${marker}</p>`)

      typeAt(editor, 7 + marker.length, 'Hello')

      expect(editor.getHTML()).toBe(`<p>Watch ${marker}</p><p>Hello</p>`)
      expect(editor.view.dom.querySelectorAll(`.${VIDEO_CHIP_CLASS}`)).toHaveLength(1)

      editor.destroy()
    })

    it('protects the marker from text typed into it', () => {
      const editor = renderEditor(`<p>${marker}</p>`)

      expect(typeAt(editor, 10, 'Hello')).toBe(true)
      expect(editor.getHTML()).toBe(`<p>${marker}</p><p>Hello</p>`)

      editor.destroy()
    })

    it('leaves the text of a row that holds a video too where it was typed', () => {
      const editor = renderEditor(`<p>Watch ${marker}</p>`)

      // Only the legacy editor writes such a row, and it stays editable: it is the caret positions
      //   of the video itself that a row of its own is made for.
      expect(typeAt(editor, 3, 'x')).toBe(false)

      editor.destroy()
    })

    it('leaves text typed away from a video to the editor', () => {
      const editor = renderEditor('<p>Hello</p>')

      expect(typeAt(editor, 3, 'x')).toBe(false)

      editor.destroy()
    })

    it('leaves text typed in a marker that is shown as no video to the editor', () => {
      const editor = renderEditor('<p>( widget: video, provider: dailymotion, id: x )</p>')

      // No chip stands in that row, so there is no row rule to keep text out of it.
      expect(typeAt(editor, 10, 'x')).toBe(false)

      editor.destroy()
    })
  })

  it('opens no form for a click on a stored video', () => {
    const editor = renderEditor(`<p>Watch ${marker} for more.</p>`)

    clickAt(editor, 10)

    expect(setFloatingPopover).not.toHaveBeenCalled()

    editor.destroy()
  })

  it('closes the form on a click in the editor', () => {
    const editor = renderEditor(`<p>Watch ${marker} for more.</p>`)

    editor.commands.openVideoEmbedForm()

    const { destroy } = vi.mocked(setFloatingPopover).mock.results.at(-1)!.value

    clickAt(editor, 3)

    expect(destroy).toHaveBeenCalled()

    editor.destroy()
  })

  it('opens no form for a click outside a video', () => {
    const editor = renderEditor(`<p>Watch ${marker} for more.</p>`)

    clickAt(editor, editor.state.doc.content.size - 1)

    expect(setFloatingPopover).not.toHaveBeenCalled()

    editor.destroy()
  })

  it('opens no form for a click in a paragraph without a video', () => {
    const editor = renderEditor('<p>Hello</p>')

    clickAt(editor, 3)

    expect(setFloatingPopover).not.toHaveBeenCalled()

    editor.destroy()
  })

  it('closes the form on a keystroke in the editor', () => {
    const editor = renderEditor('<p>Hello</p>')

    editor.commands.openVideoEmbedForm()

    const { destroy } = vi.mocked(setFloatingPopover).mock.results.at(-1)!.value

    editor.view.someProp('handleKeyDown', (handleKeyDown) =>
      handleKeyDown(editor.view, new KeyboardEvent('keydown', { key: 'a' })),
    )

    expect(destroy).toHaveBeenCalled()

    editor.destroy()
  })

  it('keeps only one form up at a time', () => {
    const editor = renderEditor('<p>Hello</p>')

    editor.commands.openVideoEmbedForm()

    const { destroy } = vi.mocked(setFloatingPopover).mock.results.at(-1)!.value

    editor.commands.openVideoEmbedForm()

    expect(destroy).toHaveBeenCalled()
    expect(setFloatingPopover).toHaveBeenCalledTimes(2)

    editor.destroy()
  })
})
