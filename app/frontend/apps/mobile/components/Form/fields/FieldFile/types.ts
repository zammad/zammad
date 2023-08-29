// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { InputHTMLAttributes } from 'vue'

export interface FieldFileProps {
  accept?: InputHTMLAttributes['accept']
  capture?: InputHTMLAttributes['capture']
  multiple?: InputHTMLAttributes['multiple']
}

export interface FieldFileContext {
  uploadFiles(files: FileList | File[]): Promise<void>
}
