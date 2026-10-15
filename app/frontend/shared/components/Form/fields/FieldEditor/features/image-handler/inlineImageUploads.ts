// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { Plugin, PluginKey, type EditorState } from '@tiptap/pm/state'
import { nextTick, ref } from 'vue'

import { useFileUploadProcessing } from '#shared/components/Form/composables/useFileUploadProcessing.ts'
import { blobToBase64, dataURLToBlob } from '#shared/utils/files.ts'
import testFlags from '#shared/utils/testFlags.ts'

import {
  copyInlineImages,
  getTicketAttachmentStoreId,
  isUploadCacheSrc,
  uploadInlineImages,
} from './imageUpload.ts'

import type { FormInlineImages, InlineImageUpload, InlineImageUploadEntry } from './types.ts'
import type { Editor } from '@tiptap/core'
import type { Node as ProseMirrorNode } from '@tiptap/pm/model'

export const inlineImageUploadsPluginKey = new PluginKey('inlineImageUploads')

// Only the browser tab that inserted an image uploads it, synced content is never claimed here.
//   Kept per form instead of per editor, so a remounted editor picks up running uploads.
const forms = new Map<string, FormInlineImages>()

const getFormInlineImages = (formId = '') => {
  let form = forms.get(formId)

  if (!form) {
    form = { uploads: ref(new Map()), editors: new Set(), runningUploads: 0 }
    forms.set(formId, form)
  }

  return form
}

const isClaimableSrc = (src: string | null): src is string =>
  !!src && !isUploadCacheSrc(src) && !src.startsWith('blob:') && !src.startsWith('cid:')

export const claimInlineImages = (formId: string | undefined, content: string | Element) => {
  const { uploads } = getFormInlineImages(formId)
  const root =
    typeof content === 'string' ? new DOMParser().parseFromString(content, 'text/html') : content

  root.querySelectorAll('img').forEach((image) => {
    const src = image.getAttribute('src')
    if (!isClaimableSrc(src)) return

    // Only a failed image is claimed again, to retry it.
    const status = uploads.value.get(src)?.status
    if (status === 'uploading' || status === 'uploaded') return

    uploads.value.set(src, { status: 'claimed', src, failedDueToCors: false })
  })
}

// The upload cache of a form is removed with the article it was sent with.
export const forgetInlineImages = (formId: string | undefined) =>
  forms.get(formId || '')?.uploads.value.clear()

export const getInlineImageUpload = (
  formId: string | undefined,
  src: string,
): InlineImageUpload | undefined => getFormInlineImages(formId).uploads.value.get(src)

const getEditorAttribute = (editor: Editor, name: string) =>
  (editor.options.editorProps.attributes as Record<string, string> | undefined)?.[name]

export const getEditorFormId = (editor: Editor) => getEditorAttribute(editor, 'data-form-id')

const getImageMimeType = (content: string) => content.match(/^data:(.+);base64/)?.at(1)

export const createInlineImageUploads = (editor: Editor) => {
  const formId = getEditorFormId(editor)
  const form = getFormInlineImages(formId)
  const { uploads } = form

  const setUploadProcessing = (processing: boolean) => {
    const name = getEditorAttribute(editor, 'name')
    if (!formId || !name) return

    const { setFileUploadProcessing, removeFileUploadProcessing } = useFileUploadProcessing(
      formId,
      name,
    )

    if (processing) setFileUploadProcessing()
    else removeFileUploadProcessing()
  }

  const syncImageNodes = (state: EditorState) => {
    const { tr } = state

    state.doc.descendants((node, pos) => {
      if (node.type.name !== 'image') return

      const entry = uploads.value.get(node.attrs.src)
      if (!entry || entry.src === node.attrs.src) return

      tr.setNodeMarkup(pos, undefined, {
        ...node.attrs,
        src: entry.src,
        content: entry.status === 'uploaded' ? null : node.attrs.content,
      })
    })

    if (!tr.docChanged) return null

    return tr.setMeta('addToHistory', false).setMeta(inlineImageUploadsPluginKey, true)
  }

  // A replacement made during an outside content write would not reach the field value.
  const notifyReplaced = (formEditor: Editor) =>
    queueMicrotask(() => {
      if (!formEditor.isDestroyed) formEditor.emit('inline-images-replaced')
    })

  const applyToEditors = () => {
    form.editors.forEach((formEditor) => {
      if (formEditor.isDestroyed) return

      const tr = syncImageNodes(formEditor.state)
      if (!tr) return

      formEditor.view.dispatch(tr)
      notifyReplaced(formEditor)
    })
  }

  const setPreview = (entry: InlineImageUploadEntry, blob: Blob) => {
    entry.previewSrc = URL.createObjectURL(blob)
    entry.src = entry.previewSrc
    uploads.value.set(entry.previewSrc, entry)

    applyToEditors()
  }

  const readSource = async (entry: InlineImageUploadEntry, node: ProseMirrorNode) => {
    const { src, content, alt, type } = node.attrs
    const name = alt || 'untitled'

    if (content) return { name, type: type || getImageMimeType(content), content }

    if (src.startsWith('data:')) {
      setPreview(entry, dataURLToBlob(src))
      return { name, type: type || getImageMimeType(src), content: src }
    }

    const response = await fetch(src)
    if (!response.ok) throw new Error(`Failed to fetch image: ${response.status}`)

    const blob = await response.blob()
    const base64 = await blobToBase64(blob)

    setPreview(entry, blob)

    return { name, type: type || getImageMimeType(base64), content: base64 }
  }

  const transferImage = async (entry: InlineImageUploadEntry, node: ProseMirrorNode) => {
    const storeId = getTicketAttachmentStoreId(node.attrs.src)
    if (storeId) return (await copyInlineImages(formId as string, [storeId]))[0]

    return (await uploadInlineImages(formId as string, [await readSource(entry, node)]))[0]
  }

  const finishUpload = (entry: InlineImageUploadEntry, result: Partial<InlineImageUploadEntry>) => {
    Object.assign(entry, result)

    if (entry.status === 'uploaded') uploads.value.set(entry.src, entry)

    applyToEditors()

    nextTick(() => {
      if (entry.previewSrc && entry.status === 'uploaded') URL.revokeObjectURL(entry.previewSrc)

      testFlags.set(
        entry.status === 'uploaded' ? 'editor.inlineImagesLoaded' : 'editor.inlineImagesFailure',
      )
    })
  }

  const startUpload = async (node: ProseMirrorNode) => {
    const { src } = node.attrs

    if (!uploads.value.has(src))
      uploads.value.set(src, { status: 'claimed', src, failedDueToCors: false })

    // Only the reactive proxy notifies the node views about status changes.
    const entry = uploads.value.get(src)!
    entry.status = 'uploading'

    // An inserted file is shown from its blob, which is released once the upload replaced it.
    if (src.startsWith('blob:')) entry.previewSrc = src

    // Registered synchronously for de-duplication, but editor updates must not be dispatched
    //   from within the view update that found the image.
    await Promise.resolve()

    if (src.startsWith('file:')) {
      finishUpload(entry, { status: 'failed' })
      return
    }

    form.runningUploads += 1
    if (form.runningUploads === 1) setUploadProcessing(true)

    try {
      const uploadedSrc = await transferImage(entry, node)

      finishUpload(
        entry,
        uploadedSrc
          ? { status: 'uploaded', src: uploadedSrc }
          : { status: 'failed', src: entry.previewSrc || src },
      )
    } catch (error) {
      finishUpload(entry, {
        status: 'failed',
        src: entry.previewSrc || src,
        // Heuristic: fetch() CORS/network issues typically surface as TypeError with generic message.
        failedDueToCors: error instanceof TypeError,
      })
    } finally {
      form.runningUploads -= 1
      if (form.runningUploads === 0) setUploadProcessing(false)
    }
  }

  const needsUpload = (node: ProseMirrorNode) => {
    const { src, content } = node.attrs

    if (!src || isUploadCacheSrc(src)) return false

    const entry = uploads.value.get(src)
    if (entry) return entry.status === 'claimed'

    // Inserted files carry their content, a blob without it is uploaded by another editor.
    return src.startsWith('blob:') && !!content
  }

  const startPendingUploads = (state: EditorState) => {
    state.doc.descendants((node) => {
      if (node.type.name === 'image' && needsUpload(node)) startUpload(node)
    })
  }

  return new Plugin({
    key: inlineImageUploadsPluginKey,
    props: {
      // Covers dropped HTML, pasted HTML is claimed by the paste handler which inserts it itself.
      transformPastedHTML: (html) => {
        claimInlineImages(formId, html)
        return html
      },
    },
    appendTransaction: (transactions, _oldState, newState) => {
      if (!transactions.some((tr) => tr.docChanged)) return null
      if (transactions.every((tr) => tr.getMeta(inlineImageUploadsPluginKey))) return null

      const tr = syncImageNodes(newState)
      if (tr) notifyReplaced(editor)

      return tr
    },
    view: (view) => {
      form.editors.add(editor)

      // A form mounted again during an upload starts without its blocking state.
      if (form.runningUploads > 0) setUploadProcessing(true)

      // A remounted editor starts from the plain content, apply what is already known.
      queueMicrotask(applyToEditors)
      startPendingUploads(view.state)

      return {
        update: (updatedView, prevState) => {
          if (updatedView.state.doc.eq(prevState.doc)) return

          startPendingUploads(updatedView.state)
        },
        destroy: () => {
          form.editors.delete(editor)
        },
      }
    },
  })
}
