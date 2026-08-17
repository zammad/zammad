// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/**
 * The minimum a file needs for the list to render it. `AttachmentWithUrls` from
 *   `useAttachments()` satisfies this, and consumers keep their own richer type through
 *   the generic parameter of `CommonFileList`, so emitted files can be handed straight
 *   to `useFilePreviewViewer()` — which matches files by object identity.
 */
export interface FileListFile {
  internalId: number
  name: string
  size?: Maybe<number>
  type?: Maybe<string>
  /** Thumbnail URL (`?preview=1`); empty when the file has no server-side preview. */
  preview: string
  downloadUrl: string
}
