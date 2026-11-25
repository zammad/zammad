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
//   reset and restores its own - unless a click focused it, as a user would. On a busy CI
//   runner a single click can take longer than the default poll timeout of one second.
export const moveCursorToStart = async (editor: Locator) => {
  await expect
    .poll(
      async () => {
        await userEvent.click(editor)
        await userEvent.keyboard(MOVE_TO_START)
        return editorSelection().from
      },
      { timeout: 5000 },
    )
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

const IMAGE_WIDTH = 1400
const IMAGE_HEIGHT = 440

export const findImage = async () => {
  await expect.poll(() => document.querySelector(EDITOR_IMAGE)).toBeTruthy()

  return document.querySelector<HTMLImageElement>(EDITOR_IMAGE)!
}

export const mountImage = async ({
  // Wider than any editor by default, so that the maximum size is the editor's width.
  naturalWidth = IMAGE_WIDTH,
  naturalHeight = IMAGE_HEIGHT,
  width,
  dir,
  textAfter = '',
  following = '',
}: {
  naturalWidth?: number
  naturalHeight?: number
  width?: number
  dir?: 'rtl'
  textAfter?: string
  following?: string
} = {}) => {
  const canvas = document.createElement('canvas')
  canvas.width = naturalWidth
  canvas.height = naturalHeight

  const size = width
    ? ` width="${width}" height="${Math.round((width * naturalHeight) / naturalWidth)}"`
    : ''

  await mountEditor({
    value: `<p${dir ? ` dir="${dir}"` : ''}><img src="${canvas.toDataURL()}" alt="Resize example"${size}>${textAfter}</p>${following}`,
  })

  const editor = (await findEditor()).element()
  const image = await findImage()

  await expect.poll(() => image.naturalWidth).toBe(naturalWidth)

  return { editor, image, paragraph: editor.querySelector('p')!, node: getNode('editor')! }
}

export const selectImage = async () => {
  await page.getByRole('img', { name: 'Resize example' }).click()

  await expect.poll(() => document.querySelector('.vdr-container')).toBeTruthy()

  return document.querySelector<HTMLElement>('.vdr-container')!
}

export const clickBesideImage = (editor: Element) =>
  page.elementLocator(editor).click({ position: { x: editor.clientWidth - 2, y: 2 } })

export const expectAspectRatio = (element: Element) => {
  const { width, height } = element.getBoundingClientRect()

  expect(Math.abs(height - (width * IMAGE_HEIGHT) / IMAGE_WIDTH)).toBeLessThanOrEqual(1)
}

const savedAttribute = (value: unknown, name: 'width' | 'height') =>
  Number(
    new DOMParser()
      .parseFromString(String(value), 'text/html')
      .querySelector('img')
      ?.getAttribute(name),
  )

export const savedWidth = (value: unknown) => savedAttribute(value, 'width')

export const savedHeight = (value: unknown) => savedAttribute(value, 'height')
