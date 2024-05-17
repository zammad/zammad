// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FileUploaded } from '#shared/components/Form/fields/FieldFile/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import log from './log.ts'

export interface ImageFileData {
  name: string
  type: string
  content: string
}

interface CompressData {
  x?: number | 'auto'
  y?: number | 'auto'
  scale?: number
  type?: string
  quality?: number | 'auto'
}

interface CompressOptions {
  compress?: boolean

  onCompress?(image: HTMLImageElement, type: string): CompressData
}

interface ValidatedFile {
  file: File
  label: string
  maxSize: number
  allowedTypes: string[]
}

export interface AllowedFile {
  label: string
  types: string[]
  size: number
}

const allowCompressMime = ['image/jpeg', 'image/png']

const getQuality = (x: number, y: number) => {
  if (x < 200 && y < 200) return 1
  if (x < 400 && y < 400) return 0.9
  if (x < 600 && y < 600) return 0.8
  if (x < 900 && y < 900) return 0.7
  return 0.6
}

export const compressImage = (
  imageSrc: string,
  type: string,
  options?: CompressOptions,
) => {
  const img = new Image()
  // eslint-disable-next-line sonarjs/cognitive-complexity
  const promise = new Promise<string>((resolve) => {
    img.onload = () => {
      const {
        x: imgX = 'auto',
        y: imgY = 'auto',
        quality = 'auto',
        scale = 1,
        type: mimeType = type,
      } = options?.onCompress?.(img, type) || {}

      const imageWidth = img.width
      const imageHeight = img.height

      log.debug('[Image Service] Image is loaded', {
        imageWidth,
        imageHeight,
      })

      let x = imgX
      let y = imgY

      if (y === 'auto' && x === 'auto') {
        x = imageWidth
        y = imageHeight
      }

      // set max x/y
      if (x !== 'auto' && x > imageWidth) x = imageWidth

      if (y !== 'auto' && y > imageHeight) y = imageHeight

      // get auto dimensions
      if (y === 'auto') {
        const factor = imageWidth / (x as number)
        y = imageHeight / factor
      }

      if (x === 'auto') {
        const factor = imageHeight / y
        x = imageWidth / factor
      }

      const canvas = document.createElement('canvas')

      if (
        (x < imageWidth && x * scale < imageWidth) ||
        (y < imageHeight && y * scale < imageHeight)
      ) {
        x *= scale
        y *= scale

        // set dimensions
        canvas.width = x
        canvas.height = y

        // draw image on canvas and set image dimensions
        const context = canvas.getContext('2d') as CanvasRenderingContext2D
        context.drawImage(img, 0, 0, x, y)
      } else {
        canvas.width = imageWidth
        canvas.height = imageHeight

        const context = canvas.getContext('2d') as CanvasRenderingContext2D
        context.drawImage(img, 0, 0, imageWidth, imageHeight)
      }

      const qualityValue =
        quality === 'auto' ? getQuality(imageWidth, imageHeight) : quality

      try {
        const base64 = canvas.toDataURL(mimeType, qualityValue)
        log.debug('[Image Service] Image is compressed', {
          quality: qualityValue,
          type: mimeType,
          x,
          y,
          size: `${(base64.length * 0.75) / 1024 / 1024} Mb`,
        })
        resolve(base64)
      } catch (e) {
        log.debug('[Image Service] Failed to compress an image', e)
        resolve(imageSrc)
      }
    }
    img.onerror = () => resolve(imageSrc)
  })
  img.src = imageSrc
  return promise
}

export const blobToBase64 = async (blob: Blob) =>
  new Promise<string>((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(reader.result as string)
    reader.onerror = () => reject(reader.error)
    reader.readAsDataURL(blob)
  })

export const convertFileList = async (
  filesList: Maybe<FileList | File[]>,
  options: CompressOptions = {},
): Promise<ImageFileData[]> => {
  const files = Array.from(filesList || [])

  const promises = files.map(async (file) => {
    let base64 = await blobToBase64(file)

    if (options?.compress && allowCompressMime.includes(file.type)) {
      base64 = await compressImage(base64, file.type, options)
    }

    return {
      name: file.name,
      type: file.type,
      content: base64,
    }
  })

  const readFiles = await Promise.all(promises)

  return readFiles.filter((file) => file.content)
}

export const loadImageIntoBase64 = async (
  src: string,
  type?: string,
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
      const mime =
        type || (img.alt?.match(/\.(jpe?g)$/i) ? 'image/jpeg' : 'image/png')
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

export const allowedImageTypes = () => {
  const { config } = useApplicationStore()

  return config['active_storage.web_image_content_types'] || []
}

export const allowedImageTypesString = () => {
  return allowedImageTypes().join(',')
}

export const canPreviewFile = (type?: Maybe<string>) => {
  if (!type) return false

  return allowedImageTypes().includes(type)
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

/**
 * @param file - file Size is in bytes
 * @param allowedSize - allowed size in bytes
 * * */
export const validateFileSizeLimit = (file: File, allowedSize: number) => {
  return file.size <= allowedSize
}

export const validateFileSizes = (
  files: File[],
  allowedFiles: AllowedFile[],
) => {
  const failedFiles: Omit<ValidatedFile, 'allowedTypes'>[] = []
  files.forEach((file) => {
    allowedFiles.forEach((allowedFile) => {
      if (!allowedFile.types.includes(file.type)) return
      if (!validateFileSizeLimit(file, allowedFile.size))
        failedFiles.push({
          file,
          label: allowedFile.label,
          maxSize: allowedFile.size,
        })
    })
  })
  return failedFiles
}

/**
 * @return {string} - A string of acceptable file types for input element.
 * * */
export const getAcceptableFileTypesString = (
  allowedFiles: AllowedFile[],
): string => {
  const result: Set<string> = new Set([])
  allowedFiles.forEach((file) => {
    file.types.forEach((type) => {
      result.add(type)
    })
  })
  return Array.from(result).join(', ')
}

/**
 * @param size file size in bytes
 ** */
export const humanizeFileSize = (size: number) => {
  if (size > 1024 * 1024 * 1024) {
    return `${Math.round((size * 10) / (1024 * 1024)) / 10} MB`
  }
  if (size > 1024) {
    return `${Math.round(size / 1024)} KB`
  }
  return `${size} Bytes`
}
