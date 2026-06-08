// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { convertInlineImages } from '#shared/components/Form/fields/FieldEditor/utils.ts'
import { getNodeByName } from '#shared/components/Form/utils.ts'
import { allowedImageTypes } from '#shared/utils/files.ts'
import log from '#shared/utils/log.ts'

import type { Extensions } from '@tiptap/core'
import type { Editor } from '@tiptap/vue-3'

interface LoadImagesOptions {
  attachNonInlineFiles: boolean
}

export const useAttachments = (extensions: Extensions, formId: string) => {
  const hasImageExtension = computed(() => {
    return extensions.some((extension) => extension.name === 'image')
  })

  const inlineImagesInEditor = (editor: Editor, files: File[]) => {
    convertInlineImages(files, editor.view.dom).then(async (urls) => {
      if (editor?.isDestroyed) return
      editor?.commands.setImages(urls)
    })
  }

  const addFilesToAttachments = (files: File[]) => {
    const attachmentsContext = getNodeByName(formId, 'attachments')?.context as unknown as
      | { uploadFiles?: (files: File[]) => void }
      | undefined
    if (attachmentsContext && !attachmentsContext.uploadFiles) {
      log.error(
        '[FieldEditorInput] Attachments field was found, but it doesn\'t provide "uploadFiles" method.',
      )
    } else {
      attachmentsContext?.uploadFiles?.(files)
    }
  }

  const imagesMimeType = allowedImageTypes()

  const loadFiles = (
    files: FileList | File[] | null | undefined,
    editor: Editor | undefined,
    options: LoadImagesOptions,
  ) => {
    if (!files) {
      return false
    }

    const inlineImages: File[] = []
    const otherFiles: File[] = []

    for (const file of files) {
      if (imagesMimeType.includes(file.type)) {
        inlineImages.push(file)
      } else {
        otherFiles.push(file)
      }
    }

    if (inlineImages.length && editor) {
      inlineImagesInEditor(editor, inlineImages)
    }

    if (options.attachNonInlineFiles && otherFiles.length) {
      addFilesToAttachments(otherFiles)
    }

    return Boolean(inlineImages.length || (options.attachNonInlineFiles && otherFiles.length))
  }

  return {
    hasImageExtension,
    loadFiles,
  }
}
