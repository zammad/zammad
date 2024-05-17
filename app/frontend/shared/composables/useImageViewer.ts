// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref, unref, watchEffect } from 'vue'

import { canPreviewFile } from '#shared/utils/files.ts'

import type { MaybeRef } from '@vueuse/shared'

interface ImagePreview {
  src?: string
  title?: string
}

export interface ImageViewerFile {
  name?: string
  content?: string
  preview?: string
  inline?: string
  type?: Maybe<string>
}

export interface ViewerOptions {
  images: ImagePreview[]
  index: number
  visible: boolean
}

export const imageViewerOptions = ref<ViewerOptions>({
  visible: false,
  index: 0,
  images: [],
})

const useImageViewer = (viewFiles: MaybeRef<ImageViewerFile[]>) => {
  const indexMap = new WeakMap<ImageViewerFile, number>()

  let images: ImagePreview[] = []

  watchEffect(() => {
    images = unref(viewFiles)
      .filter((file) => canPreviewFile(file.type))
      .map((image, index) => {
        // we need to keep track of indexes, because they might
        // be different from original files, if they had non-image uploads
        indexMap.set(image, index)
        return {
          src: image.inline || image.preview || image.content,
          title: image.name,
        }
      })
  })

  const showImage = (image: ImageViewerFile) => {
    const foundIndex = indexMap.get(image) ?? 0
    imageViewerOptions.value = {
      index: foundIndex,
      images,
      visible: true,
    }
  }

  const hideImage = () => {
    imageViewerOptions.value = {
      images: [],
      index: 0,
      visible: false,
    }
  }

  const isViewable = (file: ImageViewerFile) => indexMap.has(file)

  return {
    isViewable,
    showImage,
    hideImage,
  }
}

export { useImageViewer }
