// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { StoredFile } from '#shared/graphql/types.ts'
import type { AllowedFile } from '#shared/utils/files.ts'

import type { Component, InputHTMLAttributes } from 'vue'

export interface FieldFileProps {
  accept?: InputHTMLAttributes['accept']
  capture?: InputHTMLAttributes['capture']
  multiple?: InputHTMLAttributes['multiple']
  allowedFiles?: AllowedFile[]
}

export type FileUploaded = Pick<StoredFile, 'id' | 'name' | 'size' | 'type'> & {
  preview?: string
  isProcessing?: boolean
}

export interface FieldFileContext {
  uploadFiles(files: FileList | File[]): Promise<void>
}

export interface FileClassMap {
  button: string
  divider?: string
  listContainer: string
  dropZoneContainer?: string
  dropZoneBorder?: string
}

export interface FieldFileVisualConfig {
  buttonComponent: Component
}
