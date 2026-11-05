// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { expect } from 'vitest'
import { page, userEvent, type Locator } from 'vitest/browser'

import type { MountOptions } from '#tests/browser/types.ts'
import { mountComponent, type mockApolloClient } from '#tests/browser/utils.ts'

import type { FieldEditorContext } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { FormUploadCacheAddDocument } from '#shared/components/Form/fields/FieldFile/graphql/mutations/uploadCache/add.api.ts'
import Form from '#shared/components/Form/Form.vue'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import type { TiptapEditorHTMLElement } from '@tiptap/core'

// ProseMirror renders `img.ProseMirror-separator` cursor helpers next to inline atoms.
export const EDITOR_IMAGE = 'img:not(.ProseMirror-separator)'

// The browser runs on Linux in the Playwright server container.
const MOVE_TO_START = '{Control>}{Home}{/Control}'
export const MOVE_TO_END = '{Control>}{End}{/Control}'

export const mountEditor = (props: Record<string, unknown> = {}, options?: MountOptions) =>
  mountComponent(
    FormKit,
    {
      id: 'editor',
      name: 'editor',
      type: 'editor',
      ...props,
    },
    options,
  )

export const mountEditorWithAttachments = (
  knowledgeBaseMeta: Record<string, unknown> = {},
  options?: MountOptions,
) =>
  mountComponent(
    Form,
    {
      schema: [
        {
          isLayout: true,
          component: 'FormGroup',
          children: [
            {
              name: 'editor',
              type: 'editor',
              props: {
                meta: {
                  mentionKnowledgeBase: {
                    attachmentsNodeName: 'attachments',
                    ...knowledgeBaseMeta,
                  },
                },
              },
            },
            {
              name: 'attachments',
              type: 'file',
              props: {
                multiple: true,
              },
            },
          ],
        },
      ],
    },
    options,
  )

// The editor itself is loaded asynchronously, after the field is mounted.
export const findEditor = async () => {
  const editor = page.getByRole('textbox')

  await expect.element(editor).toBeInTheDocument()

  return editor
}

export const editorHtml = () => page.getByRole('textbox').element().innerHTML

export const editorElements = (selector: string) =>
  Array.from(page.getByRole('textbox').element().querySelectorAll<HTMLElement>(selector))

// tiptap keeps its editor on the element for tests.
const tiptapEditor = () => (page.getByRole('textbox').element() as TiptapEditorHTMLElement).editor!

const editorSelection = () => tiptapEditor().state.selection

// Within 200 ms of focusing, ProseMirror takes a cursor at the document start for a browser
//   reset and restores its own.
export const moveCursorToStart = async (editor: Locator) => {
  await expect
    .poll(async () => {
      await userEvent.type(editor, MOVE_TO_START)
      return editorSelection().from
    })
    .toBe(1)
}

const editorOwnsCursor = () => {
  const { view } = tiptapEditor()
  const { anchorNode, anchorOffset, focusNode, focusOffset } = document.getSelection()!

  return (
    !!anchorNode &&
    !!focusNode &&
    view.posAtDOM(anchorNode, anchorOffset) === view.state.selection.anchor &&
    view.posAtDOM(focusNode, focusOffset) === view.state.selection.head
  )
}

// The editor takes a moved cursor over only on the next `selectionchange`: keys and commands that
//   read its selection before that still act on the old position.
export const pressCursorKey = async (keys: string) => {
  await userEvent.keyboard(keys)
  await expect.poll(editorOwnsCursor).toBe(true)
}

export const selectText = (direction: 'left' | 'right', size: number) =>
  pressCursorKey(
    `{Shift>}${(direction === 'right' ? '{ArrowRight}' : '{ArrowLeft}').repeat(size)}{/Shift}`,
  )

const loadedEditorContext = () => {
  const context = getNode('editor')?.context as Required<FieldEditorContext> | undefined

  if (!context || !('_loaded' in context)) return undefined

  return context
}

// The searches are debounced: on a loaded runner, a pause within the typed term can search for a
//   part of it first.
export const waitForLastSearch = async (
  suggestions: { waitForCalls: () => Promise<{ variables: Record<string, unknown> }[]> },
  variables: Record<string, unknown>,
) => {
  await expect
    .poll(async () => (await suggestions.waitForCalls()).at(-1)?.variables)
    .toMatchObject(variables)
}

export const getEditorContext = async () => {
  await expect.poll(loadedEditorContext).toBeDefined()

  return loadedEditorContext()!
}

export const mockImageUpload = (client: ReturnType<typeof mockApolloClient>, id: number) =>
  client.setRequestHandler(FormUploadCacheAddDocument, async () => ({
    data: {
      formUploadCacheAdd: {
        __typename: 'FormUploadCacheAddPayload',
        uploadedFiles: [
          {
            __typename: 'StoredFile',
            id: convertToGraphQLId('Store', id),
            name: 'file.png',
            size: 12393,
            type: 'image/png',
          },
        ],
      },
    },
  }))
