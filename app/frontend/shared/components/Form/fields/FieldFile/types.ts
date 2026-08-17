// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { StoredFile } from '#shared/graphql/types.ts'
import type { AllowedFile } from '#shared/utils/files.ts'

import type { SetOptional } from 'type-fest'
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

/** An uploaded file plus the locally held data URI, used for preview and download. */
export type FieldFileUploaded = FileUploaded & { content?: string }

/** A file that is still being sent to the upload cache, so it has no id yet. */
export type FieldFileLoading = SetOptional<FileUploaded, 'id'>

/**
 * The contract every app implements for `fieldFile.listComponent`. Desktop renders
 *   `CommonFileList`, mobile renders `CommonFilePreview` — the field itself only owns the
 *   upload cache, validation and the drop zone.
 */
export interface FieldFileListProps {
  files: FieldFileUploaded[]
  loadingFiles: FieldFileLoading[]
  canInteract: boolean
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
  /** Renders the uploaded files, see `FieldFileListProps`. */
  listComponent: Component
}
