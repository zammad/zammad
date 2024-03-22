// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { InputHTMLAttributes } from 'vue'
import type { AllowedFile } from '#shared/utils/files.ts'

export interface FieldFileProps {
  accept?: InputHTMLAttributes['accept']
  capture?: InputHTMLAttributes['capture']
  multiple?: InputHTMLAttributes['multiple']
  allowedFiles?: AllowedFile[]
}

export interface FieldFileContext {
  uploadFiles(files: FileList | File[]): Promise<void>
}
