// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Editor } from '@tiptap/core'
import type { Ref } from 'vue'

export interface InlineImageUpload {
  status: 'claimed' | 'uploading' | 'uploaded' | 'failed'
  src: string
  failedDueToCors: boolean
}

export interface InlineImageUploadEntry extends InlineImageUpload {
  previewSrc?: string
}

export interface FormInlineImages {
  // Keyed by every src an image passes through: the original source, its preview and the result.
  uploads: Ref<Map<string, InlineImageUploadEntry>>
  editors: Set<Editor>
  runningUploads: number
}
