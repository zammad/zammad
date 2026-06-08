// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { ImageViewerFile } from '#shared/composables/useImageViewer.ts'

import type { Ref } from 'vue'

export const useHtmlInlineImages = (
  inlineImages: Ref<ImageViewerFile[]>,
  onClick: (int: number) => void,
) => {
  const populateInlineImages = (element: HTMLDivElement) => {
    inlineImages.value.splice(0)

    element.querySelectorAll('img').forEach((image) => {
      const mime = (image.alt || image.src)?.match(/\.(jpe?g)$/i) ? 'image/jpeg' : 'image/png'

      const preview: ImageViewerFile = {
        name: image.alt,
        inline: image.src,
        type: mime,
      }

      image.classList.add('cursor-pointer')

      if (image.style.width) {
        image.style.maxWidth = image.style.width
        image.style.width = '100%'
      }

      const index = inlineImages.value.push(preview) - 1
      image.onclick = (event) => {
        event.preventDefault()
        event.stopPropagation()
        onClick(index)
      }
    })
  }

  return {
    populateInlineImages,
  }
}
