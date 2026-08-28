// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { Extension } from '@tiptap/core'
import { Plugin } from '@tiptap/pm/state'
import { Decoration, DecorationSet } from '@tiptap/pm/view'
import { type VueRenderer } from '@tiptap/vue-3'

import { useRawHTMLIcon } from '#shared/components/CommonIcon/useRawHTMLIcon.ts'
import {
  type DetectedVideo,
  parseVideoWidgetMarker,
  VIDEO_EMBED_ACTION_NAME,
  VIDEO_PROVIDER_LABELS,
  videoMarkerRangeAt,
  videoMarkerRanges,
} from '#shared/components/Form/fields/FieldEditor/features/video-embed/videoEmbed.ts'
// We can't async load VideoEmbedForm, otherwise initially VueRenderer will not render it
import VideoEmbedForm from '#shared/components/Form/fields/FieldEditor/features/video-embed/VideoEmbedForm.vue'
import { setFloatingPopover } from '#shared/components/Form/fields/FieldEditor/utils.ts'
import { useAppName } from '#shared/composables/useAppName.ts'
import { i18n } from '#shared/i18n.ts'

import type { Editor } from '@tiptap/core'
import type { Node as ProseMirrorNode } from '@tiptap/pm/model'

const appName = useAppName()

export const VIDEO_MARKER_CLASS = 'video-widget-marker'
export const VIDEO_CHIP_CLASS = 'video-widget-chip'

/**
 * What the video is called on its chip: the service it lives on, the server it lives on for a
 * self-hosted one, and which video it is.
 */
const videoChipLabel = ({ provider, id, host }: DetectedVideo) =>
  [i18n.t('%s video', VIDEO_PROVIDER_LABELS[provider]), host, id].filter(Boolean).join(' · ')

/**
 * The chip a stored video is shown as, standing in for the player the reader gets. Built as plain
 * DOM rather than as a component: a decoration is redrawn from scratch whenever the document
 * changes, and there is nothing here that needs a Vue instance per video.
 */
const videoChip = (editor: Editor, video: DetectedVideo, getPosition: () => number | undefined) => {
  const chip = document.createElement('figure')

  chip.className = VIDEO_CHIP_CLASS
  // Set as an attribute rather than through the property, which not every DOM implementation
  //   reflects back onto the element.
  chip.setAttribute('contenteditable', 'false')

  const preview = document.createElement('div')

  preview.className = `${VIDEO_CHIP_CLASS}-preview`
  preview.innerHTML = useRawHTMLIcon({ name: 'camera-video', size: 'xl', decorative: true })

  const removeButton = document.createElement('button')

  removeButton.className = `${VIDEO_CHIP_CLASS}-remove-button`
  removeButton.type = 'button'
  removeButton.title = i18n.t('Remove video')
  removeButton.innerHTML = useRawHTMLIcon({ name: 'trash3', size: 'tiny', decorative: true })

  removeButton.addEventListener('click', (event) => {
    const position = getPosition()

    if (position === undefined) return

    // This button is the only thing that acts on the click: neither the editor's own click
    //   handling, nor the handler that closes a floating form on a click outside it.
    event.stopPropagation()

    const range = videoMarkerRangeAt(editor, position)

    if (!range) return

    // Straight out, without asking: the video is back with one undo, and embedding another one is
    //   a click away.
    editor.commands.closeVideoEmbedForm()
    editor.chain().focus().deleteRange(range).run()
  })

  chip.appendChild(removeButton)

  const caption = document.createElement('figcaption')

  caption.className = `${VIDEO_CHIP_CLASS}-caption`

  // Text, never markup: the id is whatever the body carries.
  caption.textContent = videoChipLabel(video)

  chip.append(preview, caption)

  return chip
}

/**
 * The chip of the video the caret sits in, which the form is placed against: the marker itself is
 * hidden, so it has no size of its own to be placed against, and a form given nothing to measure
 * ends up in the corner of the screen.
 *
 * Chips are drawn in document order, so the nth video of the document is the nth chip in the
 * editor's DOM — counting only the markers that are shown as one.
 */
const videoChipAtCaret = (editor: Editor) => {
  const caret = editor.state.selection.from

  const index = videoMarkerRanges(editor.state.doc)
    .filter(({ marker }) => parseVideoWidgetMarker(marker))
    .findIndex(({ from, to }) => from <= caret && caret <= to)

  if (index === -1) return undefined

  return editor.view.dom.querySelectorAll<HTMLElement>(`.${VIDEO_CHIP_CLASS}`)[index]
}

/**
 * Text typed in the row of a stored video — in front of the chip, inside its hidden marker, or
 * right after it, which is where a click in the empty space of the row leaves the caret. A row
 * holds one video and nothing else, so the text starts a row of its own instead: above the video
 * when it was typed in front of it, below the video otherwise.
 *
 * A row written by the video tool holds nothing but the marker, so this covers every caret position
 * in it. Text elsewhere in a row that also holds a video — a body written by the legacy editor, the
 * only way to get one — is left to the editor, so that such a row can still be edited.
 */
const handleTextInVideoRow = (editor: Editor, from: number, to: number, text: string) => {
  // A selection being typed over is the editor's own affair — replacing a whole video that way is
  //   how a marker is written over.
  if (from !== to) return false

  const range = videoMarkerRangeAt(editor, from)

  if (!range) return false

  const $position = editor.state.doc.resolve(from)
  const row =
    from === range.from ? $position.before($position.depth) : $position.after($position.depth)

  editor
    .chain()
    .insertContentAt(row, { type: 'paragraph', content: [{ type: 'text', text }] })
    // The caret follows the text into the row it started: one position for the paragraph itself,
    //   then past what was typed.
    .setTextSelection(row + 1 + text.length)
    .run()

  return true
}

/**
 * A stored video is the literal marker text in the body, and in the legacy editor that is what an
 * author sees while writing. Here it is shown as a chip instead — as a decoration, so the document
 * itself is untouched and `getHTML()` keeps emitting the marker verbatim: the marker text is hidden
 * and the chip is drawn in its place.
 *
 * A marker the server would not expand is left as it is, which is also what a body written against
 * a provider that has since been removed looks like.
 */
const videoMarkerDecorations = (editor: Editor, doc: ProseMirrorNode) =>
  DecorationSet.create(
    doc,
    videoMarkerRanges(doc).flatMap(({ from, to, marker }, index) => {
      const video = parseVideoWidgetMarker(marker)

      if (!video) return []

      return [
        Decoration.inline(from, to, { class: VIDEO_MARKER_CLASS }),
        Decoration.widget(from, (_view, getPosition) => videoChip(editor, video, getPosition), {
          // Drawn after a caret at the start of the row, so that the caret is rendered in front of
          //   the chip rather than behind it.
          side: 1,
          // Lets ProseMirror keep the chip it has already drawn when the document changes around
          //   it, instead of building a new one on every keystroke.
          key: `${VIDEO_CHIP_CLASS}-${index}-${marker}`,
          // The chip's buttons handle their own clicks; ProseMirror must not also act on them.
          stopEvent: () => true,
        }),
        Decoration.widget(to, () => document.createElement('span'), {
          // Where the caret goes at the end of the row. Without it the caret would be put inside
          //   the hidden marker, which the browser never laid out and therefore draws a caret for
          //   wherever it likes — at the far end of the row, in practice. An empty element of no
          //   width is something it can measure, and ProseMirror puts the caret behind it rather
          //   than in the text it follows, since a widget is not a place a caret can go into.
          side: -1,
          key: `${VIDEO_CHIP_CLASS}-end-${index}-${marker}`,
        }),
      ]
    }),
  )

/**
 * Keys that act on a whole stored video, since the marker it is stored as is hidden: without this
 * an author would be deleting and stepping over characters they cannot see.
 */
const handleMarkerKey = (editor: Editor, event: KeyboardEvent) => {
  const { selection } = editor.state

  if (!selection.empty) return false
  if (event.shiftKey || event.metaKey || event.ctrlKey || event.altKey) return false

  const range = videoMarkerRangeAt(editor, selection.from)

  if (!range) return false

  const { from, to } = range
  const caret = selection.from

  switch (event.key) {
    // Deleting from either edge, or from within, takes the whole video with it.
    case 'Backspace':
      if (caret === from) return false

      editor.commands.closeVideoEmbedForm()
      return editor.commands.deleteRange(range)
    case 'Delete':
      if (caret === to) return false

      editor.commands.closeVideoEmbedForm()
      return editor.commands.deleteRange(range)
    // Stepping over it rather than through its hidden characters.
    case 'ArrowLeft':
      if (caret === from) return false

      return editor.commands.setTextSelection(from)
    case 'ArrowRight':
      if (caret === to) return false

      return editor.commands.setTextSelection(to)
    default:
      return false
  }
}

/**
 * The form that embeds a video, opened next to the caret like the link form. The video itself is a
 * plain-text marker in the body rather than a node of this extension's own — the server expands it
 * on read (`KnowledgeBaseRichText.expand_video_widgets`) — so all this extension owns is the form.
 */
export default Extension.create({
  name: VIDEO_EMBED_ACTION_NAME,

  addCommands() {
    let formComponent: VueRenderer | null = null

    const destroyForm = () => {
      if (!formComponent) return

      formComponent.element?.remove()
      formComponent.destroy()
      formComponent = null
    }

    return {
      openVideoEmbedForm: () => () => {
        // Never a second form beside the one that is already up.
        destroyForm()

        formComponent = setFloatingPopover(
          VideoEmbedForm,
          this.editor,
          {},
          {
            // A form opened over a stored video hangs under that video's chip, wherever it was
            //   opened from; one for a video that is not there yet goes next to the caret.
            anchor: videoChipAtCaret(this.editor),
            onClose: () => {
              this.editor.commands.closeVideoEmbedForm()
            },
          },
        )

        return true
      },
      closeVideoEmbedForm: () => () => {
        destroyForm()
        return false
      },
    }
  },

  addProseMirrorPlugins() {
    const { editor } = this

    const plugins = [
      new Plugin({
        state: {
          init: (_configuration, state) => videoMarkerDecorations(editor, state.doc),
          // Only a changed document can change where the markers are; every other transaction
          //   leaves the set it produced standing.
          apply: (transaction, decorations) =>
            transaction.docChanged ? videoMarkerDecorations(editor, transaction.doc) : decorations,
        },
        props: {
          decorations(state) {
            return this.getState(state)
          },
          handleKeyDown(_view, event) {
            return handleMarkerKey(editor, event)
          },
          handleTextInput(_view, from, to, text) {
            return handleTextInVideoRow(editor, from, to, text)
          },
        },
      }),
    ]

    // Only desktop has the video embed form.
    if (appName !== 'desktop') return plugins

    plugins.push(
      new Plugin({
        props: {
          handleKeyDown() {
            return editor.commands.closeVideoEmbedForm()
          },
          // A click anywhere in the editor closes the form, a stored video included: the only way
          //   to the form of a video that is already there is that video's own replace button.
          handleClick() {
            return editor.commands.closeVideoEmbedForm()
          },
        },
      }),
    )

    return plugins
  },
})
