// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FileUploaded } from '@shared/components/Form/fields/FieldFile/types'
import { useApplicationStore } from '@shared/stores/application'

export interface ImageFileData {
  name: string
  type: string
  content: string
}

export const blobToBase64 = async (blob: Blob) =>
  new Promise<string>((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(reader.result as string)
    reader.onerror = () => reject(reader.error)
    reader.readAsDataURL(blob)
  })

export const convertFileList = async (
  filesList?: Maybe<FileList>,
): Promise<ImageFileData[]> => {
  const files = Array.from(filesList || [])

  const promises = files.map(async (file) => {
    return {
      name: file.name,
      type: file.type,
      content: await blobToBase64(file),
    }
  })

  const readFiles = await Promise.all(promises)

  return readFiles.filter((file) => file.content)
}

export const loadImageIntoBase64 = async (
  src: string,
  alt?: string,
): Promise<string | null> => {
  const img = new Image()
  img.crossOrigin = 'anonymous'
  const promise = new Promise<string | null>((resolve) => {
    img.onload = () => {
      const canvas = document.createElement('canvas')
      canvas.width = img.width
      canvas.height = img.height
      const ctx = canvas.getContext('2d')
      ctx?.drawImage(img, 0, 0, img.width, img.height)
      const mime = img.alt?.match(/\.(jpe?g)$/i) ? 'image/jpeg' : 'image/png'
      try {
        const base64 = canvas.toDataURL(mime)
        resolve(base64)
      } catch {
        resolve(null)
      }
    }
    img.onerror = () => {
      resolve(null)
    }
  })
  img.alt = alt || ''
  img.src = src
  return promise
}

export const canDownloadFile = (type?: Maybe<string>) => {
  return Boolean(type && type !== 'text/html')
}

export const canPreviewFile = (type?: Maybe<string>) => {
  if (!type) return false

  const { config } = useApplicationStore()

  const allowedPreviewContentTypes =
    (config['active_storage.web_image_content_types'] as string[]) || []

  return allowedPreviewContentTypes.includes(type)
}

export const convertFilesToAttachmentInput = (
  formId: string,
  attachments?: FileUploaded[],
) => {
  const files = attachments?.map((file) => ({
    name: file.name,
    type: file.type,
  }))
  if (!files || !files.length) return null
  return {
    files,
    formId,
  }
}
