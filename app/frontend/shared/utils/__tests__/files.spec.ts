// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'

import {
  getAcceptableFileTypesString,
  humanizeFileSize,
  validateFileSizes,
  type AllowedFile,
  sanitizedContentType,
  canPreviewFile,
} from '#shared/utils/files.ts'

describe('files utility', () => {
  describe('getAcceptableFileTypesString', () => {
    it('returns a string of acceptable file types for native input', () => {
      const allowedFiles: AllowedFile[] = [
        { label: 'Image', types: ['image/jpeg', 'image/png'], size: 5000000 },
        { label: 'Document', types: ['application/pdf'], size: 10000000 },
      ]

      const result = getAcceptableFileTypesString(allowedFiles)
      expect(result).toBe('image/jpeg, image/png, application/pdf')
    })

    it('returns an empty string when no file types are allowed', () => {
      const allowedFiles: AllowedFile[] = []
      const result = getAcceptableFileTypesString(allowedFiles)
      expect(result).toBe('')
    })
  })

  describe('humanizeFileSize', () => {
    it('returns file size in MB when size is more than 1GB', () => {
      const size = 1024 * 1024 * 1024 * 1.5 // 1.5GB
      const result = humanizeFileSize(size)
      expect(result).toBe('1536 MB')
    })

    it('returns file size in KB when size is more than 1MB and less than 1GB', () => {
      const size = 1024 * 1024 * 0.5 // 0.5MB
      const result = humanizeFileSize(size)
      expect(result).toBe('512 KB')
    })

    it('returns file size in Bytes when size is less than 1MB', () => {
      const size = 1024 * 0.5 // 0.5KB
      const result = humanizeFileSize(size)
      expect(result).toBe('512 Bytes')
    })
  })

  describe('validateFileSizes', () => {
    it('returns an empty array when all files are within the allowed size', () => {
      const file1 = new File(['content'], 'file1.txt', { type: 'text/plain' })
      const file2 = new File(['content'], 'file2.txt', { type: 'text/plain' })
      const files: File[] = [file1, file2]

      const allowedFiles: AllowedFile[] = [{ label: 'Text', types: ['text/plain'], size: 5000000 }]

      const result = validateFileSizes(files, allowedFiles)

      expect(result).toEqual([])
    })

    it('returns an array of failed files when some files exceed the allowed size', () => {
      // :TODO let's add createFile util
      const file1 = new File(['content'], 'file1.txt', { type: 'text/plain' })
      Object.defineProperty(file1, 'size', { value: 6000000 })
      const file2 = new File(['content'], 'file1.jpeg', { type: 'image/jpeg' })
      Object.defineProperty(file2, 'size', { value: 6000000 })
      const file3 = new File(['content'], 'file1.jpeg', { type: 'image/jpeg' })
      Object.defineProperty(file3, 'size', { value: 4000000 })

      const files = [file1, file2, file3]
      const allowedFiles: AllowedFile[] = [
        { label: 'Text', types: ['text/plain'], size: 5000000 },
        { label: 'Image', types: ['image/jpeg'], size: 5000000 },
      ]

      const result = validateFileSizes(files, allowedFiles)

      expect(result).toEqual([
        { file: file1, label: 'Text', maxSize: 5000000 },
        { file: file2, label: 'Image', maxSize: 5000000 },
      ])
    })
  })

  describe('sanitizedContentType', () => {
    it('returns the sanitized content type without parameters', () => {
      const type = 'image/jpeg; charset=UTF-8'
      const result = sanitizedContentType(type)
      expect(result).toBe('image/jpeg')
    })

    it('returns the original content type if no parameters are present', () => {
      const type = 'application/pdf'
      const result = sanitizedContentType(type)
      expect(result).toBe('application/pdf')
    })

    it('returns undefined when input is undefined', () => {
      const result = sanitizedContentType(undefined)
      expect(result).toBeUndefined()
    })
  })

  describe('canPreviewFile', () => {
    beforeEach(() => {
      mockApplicationConfig({
        'active_storage.web_image_content_types': [
          'image/png',
          'image/jpeg',
          'image/gif',
          'image/webp',
        ],
      })
    })

    it('returns "image" for allowed image type', () => {
      const type = 'image/png'
      const result = canPreviewFile(type)
      expect(result).toBe('image')
    })

    it('returns "calendar" for allowed calendar type', () => {
      const type = 'text/calendar; charset=UTF-8'
      const result = canPreviewFile(type)
      expect(result).toBe('calendar')
    })

    it('returns false for disallowed file type', () => {
      const type = 'application/octet-stream'
      const result = canPreviewFile(type)
      expect(result).toBe(false)
    })
  })
})
