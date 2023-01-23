// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { StoredFile } from '@shared/graphql/types'
import type { InputHTMLAttributes } from 'vue'

export interface FieldFileProps {
  accept?: InputHTMLAttributes['accept']
  capture?: InputHTMLAttributes['capture']
  multiple?: InputHTMLAttributes['multiple']
}

export type FileUploaded = Pick<StoredFile, 'id' | 'name' | 'size' | 'type'> & {
  content?: string
}
