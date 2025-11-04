// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { autoUpdate, computePosition, flip, shift } from '@floating-ui/dom'
import { type Editor, getHTMLFromFragment } from '@tiptap/core'
import { posToDOMRect, VueRenderer } from '@tiptap/vue-3'

import type { SetFloatingPopoverOptions } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { convertFileList } from '#shared/utils/files.ts'

import type { Component } from 'vue'

const addTableClasses = (container: HTMLDivElement) => {
  container.querySelectorAll('table').forEach((table) => {
    // Skip tables that are nested within blockquote elements.
    if (table.closest('blockquote')) return

    // Skip tables that are nested within signature containers.
    if (table.closest('[data-signature="true"]')) return

    table.classList.add('zammad-table')
  })

  return container
}

export const transformEditorHtml = (htmlContent: string): string => {
  let container = document.createElement('div')

  container.innerHTML = htmlContent

  container = addTableClasses(container)

  return container.innerHTML
}

export const convertInlineImages = (
  inlineImages: FileList | File[],
  editorElement: HTMLElement,
) => {
  return convertFileList(inlineImages, {
    compress: true,
    onCompress: () => {
      const editorWidth = editorElement.clientWidth
      const maxWidth = editorWidth > 1000 ? editorWidth : 1000
      return {
        x: maxWidth,
        scale: 2,
        type: 'image/jpeg',
      }
    },
  })
}

/*
 * Selection specific utils
 */
export const getSelection = (editor: Editor) => editor.state.selection

const selectionIsWithinSameParent = (selection: Editor['state']['selection']) => {
  const { $from, $to, empty } = selection

  if (empty) return false

  return $from.parent === $to.parent
}

export const getHTMLContentBetweenSelection = (
  editor: Editor,
  { from, to }: { from: number; to: number },
) => {
  const slice = editor.state.doc.cut(from, to)

  let html = getHTMLFromFragment(slice.content, editor.schema)

  if (selectionIsWithinSameParent(editor.state.selection)) {
    // remove the outer block wrapper
    html = html.slice(html.indexOf('>') + 1, html.lastIndexOf('<'))
  }

  return html
}

export const updateSelectedContent = (editor: Editor, content: string) => {
  const { $from, $to } = editor.state.selection

  const cleanContent = content.replace(/\s*\n\s*/g, '')

  return editor.commands.insertContentAt({ from: $from.pos, to: $to.pos }, cleanContent, {
    parseOptions: {
      preserveWhitespace: false,
    },
    errorOnInvalidContent: false,
  })
}

/*
 * Floating-ui
 */
export const updatePosition = (editor: Editor, element: HTMLElement) => {
  const virtualElement = {
    getBoundingClientRect: () =>
      posToDOMRect(editor.view, editor.state.selection.from, editor.state.selection.to),
  }

  computePosition(virtualElement, element, {
    placement: 'bottom-start',
    strategy: 'fixed',
    middleware: [shift(), flip()],
  }).then(({ x, y, strategy }) => {
    element.style.position = strategy
    element.style.left = `${x}px`
    element.style.top = `${y}px`
  })
}

export const getActiveNodeOrMark = (editor: Editor) => {
  const { node: domNode } = editor.view.domAtPos(editor.state.selection.from)

  return domNode.nodeType === Node.TEXT_NODE ? domNode.parentElement : (domNode as HTMLElement)
}

export const setAutoUpdate = (editor: Editor, element: HTMLElement) => {
  const anchorNode = getActiveNodeOrMark(editor)

  if (!anchorNode) {
    console.warn('FieldEditor: Could not find valid anchor node for autoUpdate.')
    return
  }

  return autoUpdate(anchorNode, element, () => updatePosition(editor, element))
}

export const autoUpdatePosition = (editor: Editor, element: HTMLElement) => {
  updatePosition(editor, element)
  setAutoUpdate(editor, element)
}

const createHandleCloseOnClick = (editor: Editor, options?: SetFloatingPopoverOptions) => {
  const handleCloseOnClick = (event: MouseEvent) => {
    if ((event.target as HTMLElement).closest('[data-id="floating-popover"]')) return
    // Editor handles click itself
    if ((event.target as HTMLElement).closest('[data-type="editor"]')) return

    document.removeEventListener('click', handleCloseOnClick)
    editor.commands.closeLinkForm()

    options?.onClose?.()
  }

  // We must do so to keep the same handler reference
  return handleCloseOnClick
}

export const setFloatingPopover = <T extends object>(
  cmp: Component,
  editor: Editor,
  props: T,
  options?: SetFloatingPopoverOptions,
) => {
  const virtualComponent = new VueRenderer(cmp, {
    props: {
      'data-id': 'floating-popover',
      editor,
      ...props,
    },
    editor,
  })

  if (!virtualComponent.element) {
    if (import.meta.env.DEV)
      console.warn('editor: Floating popover could`t get imported. Did you async load it?')
    return null
  }
  ;(virtualComponent.element as HTMLElement).style.position = 'absolute'

  document.body.appendChild(virtualComponent.element)

  autoUpdatePosition(editor, virtualComponent.element as HTMLElement)

  const clickHandler = createHandleCloseOnClick(editor, options)

  document.addEventListener('click', clickHandler)

  return virtualComponent
}
