// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { expect } from 'vitest'
import { page, userEvent } from 'vitest/browser'

import { mountComponent, type mockApolloClient, type MountOptions } from '#tests/browser/utils.ts'

import type { FieldEditorContext } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { FormUploadCacheAddDocument } from '#shared/components/Form/fields/FieldFile/graphql/mutations/uploadCache/add.api.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

// ProseMirror renders `img.ProseMirror-separator` cursor helpers next to inline atoms.
export const EDITOR_IMAGE = 'img:not(.ProseMirror-separator)'

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

// The editor itself is loaded asynchronously, after the field is mounted.
export const findEditor = async () => {
  const editor = page.getByRole('textbox')

  await expect.element(editor).toBeInTheDocument()

  return editor
}

export const editorHtml = () => page.getByRole('textbox').element().innerHTML

export const editorElements = (selector: string) =>
  Array.from(page.getByRole('textbox').element().querySelectorAll<HTMLElement>(selector))

export const selectText = (direction: 'left' | 'right', size: number) =>
  userEvent.keyboard(
    `{Shift>}${(direction === 'right' ? '{ArrowRight}' : '{ArrowLeft}').repeat(size)}{/Shift}`,
  )

const loadedEditorContext = () => {
  const context = getNode('editor')?.context

  if (!context || !('_loaded' in context)) return undefined

  return context as unknown as Required<FieldEditorContext>
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
