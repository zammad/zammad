// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getHTMLFromFragment, type Extensions } from '@tiptap/core'
import { Fragment } from '@tiptap/pm/model'
import { computed } from 'vue'

import { convertInlineImages } from '#shared/components/Form/fields/FieldEditor/utils.ts'
import { getNodeByName } from '#shared/components/Form/utils.ts'
import { allowedImageTypes, type ImageFileData } from '#shared/utils/files.ts'
import log from '#shared/utils/log.ts'

import type { Editor } from '@tiptap/vue-3'

interface LoadImagesOptions {
  attachNonInlineFiles: boolean
}

export const useAttachments = (extensions: Extensions, formId: string) => {
  const hasImageExtension = computed(() => {
    return extensions.some((extension) => extension.name === 'image')
  })

  // Reading and scaling an image takes a moment, in which the editor does not hold it yet.
  const imagesOnTheirWay = new Set<{ images: Promise<ImageFileData[]>; isTaken: boolean }>()

  const inlineImagesInEditor = (editor: Editor, files: File[]) => {
    const entry = { images: convertInlineImages(files, editor.view.dom), isTaken: false }

    imagesOnTheirWay.add(entry)

    entry.images
      .finally(() => imagesOnTheirWay.delete(entry))
      .then((images) => {
        if (entry.isTaken || editor?.isDestroyed) return
        editor?.commands.setImages(images)
      })
  }

  const takeImagesOnTheirWay = (editor: Editor) => {
    if (!imagesOnTheirWay.size) return undefined

    const taken = [...imagesOnTheirWay]

    taken.forEach((entry) => {
      entry.isTaken = true
    })

    return Promise.all(taken.map(({ images }) => images.catch(() => []))).then((images) =>
      getHTMLFromFragment(
        Fragment.from(
          images
            .flat()
            .map(({ content, name, type }) =>
              editor.schema.nodes.image.create({ src: content, alt: name, type }),
            ),
        ),
        editor.schema,
      ),
    )
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
    takeImagesOnTheirWay,
  }
}
