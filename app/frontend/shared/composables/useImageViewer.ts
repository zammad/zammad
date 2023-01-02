// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { canPreviewFile } from '@shared/utils/files'
import type { MaybeRef } from '@vueuse/shared'
import { ref, unref, watchEffect } from 'vue'

interface ImagePreview {
  src?: string
  title?: string
}

interface CachedFile {
  name?: string
  content?: string
  type?: Maybe<string>
}

interface ViewerOptions {
  images: ImagePreview[]
  index: number
  visible: boolean
}

export const imageViewerOptions = ref<ViewerOptions>({
  visible: false,
  index: 0,
  images: [],
})

const useImageViewer = (viewFiles: MaybeRef<CachedFile[]>) => {
  const indexMap = new WeakMap<CachedFile, number>()

  let images: ImagePreview[] = []

  watchEffect(() => {
    images = unref(viewFiles)
      .filter((file) => canPreviewFile(file.type))
      .map((image, index) => {
        // we need to keep track of indexes, because they might
        // be different from original files, if they had non-image uploads
        indexMap.set(image, index)
        return {
          src: image.content,
          title: image.name,
        }
      })
  })

  const showImage = (image: CachedFile) => {
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

  const isViewable = (file: CachedFile) => indexMap.has(file)

  return {
    isViewable,
    showImage,
    hideImage,
  }
}

export default useImageViewer
