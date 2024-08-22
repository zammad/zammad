// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { useImageViewer } from '#shared/composables/useImageViewer.ts'
import type { FilePreview } from '#shared/utils/files.ts'

import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'

import type { MaybeRef } from '@vueuse/shared'

interface ImagePreview {
  src?: string
  title?: string
}

export interface ViewerFile {
  id?: string
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

export const useFilePreviewViewer = (viewFiles: MaybeRef<ViewerFile[]>) => {
  const { showImage } = useImageViewer(viewFiles)

  const calendarPreviewFlyout = useFlyout({
    name: 'common-calendar-preview',
    component: () =>
      import(
        '#desktop/components/CommonCalendarPreviewFlyout/CommonCalendarPreviewFlyout.vue'
      ),
  })

  const showPreview = (type: FilePreview, filePreviewfile: ViewerFile) => {
    if (type === 'image') {
      showImage(filePreviewfile)
    }

    if (type === 'calendar') {
      calendarPreviewFlyout.open({
        fileId: filePreviewfile.id,
        fileType: filePreviewfile.type,
        fileName: filePreviewfile.name,
      })
    }
  }

  return {
    showPreview,
  }
}
