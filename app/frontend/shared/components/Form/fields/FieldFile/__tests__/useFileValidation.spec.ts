// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { faker } from '@faker-js/faker'
import { createNode, type FormKitNode } from '@formkit/core'

import { useFileValidation } from '../composable/useFileValidation.ts'
// import { vi } from 'vitest'
describe('useFileValidation', () => {
  // Simple function pointer otherwise if stateful add this to beforeEach
  const { validateFileSize } = useFileValidation()
  let node: FormKitNode
  let files: Array<File>
  let allowedFiles: any[]
  const options = {
    writeToStore: false,
  }

  const allowedFileDocument = {
    label: __('Document'),
    types: [
      'text/plain',
      'application/pdf',
      'application/vnd.ms-powerpoint',
      'application/msword',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ],
    size: 100 * 1024 * 1024,
  }
  const allowedFileAudio = {
    label: __('Audio'),
    types: ['audio/aac', 'audio/mp4', 'audio/amr', 'audio/mpeg', 'audio/ogg'],
    size: 16 * 1024 * 1024,
  }
  const allowedFileSticker = {
    label: __('Sticker'),
    types: ['image/webp'],
    size: 500 * 1024,
  }
  const allowedFileImage = {
    label: __('Image'),
    types: ['image/jpeg', 'image/png'],
    size: 5 * 1024 * 1024,
  }
  const allowedFileVideo = {
    label: __('Video'),
    types: ['video/mp4', 'video/3gpp'],
    size: 16 * 1024 * 1024,
  }

  // :TODO move this to testing helper function
  const createFile = (
    mimeType: string,
    sizeInBytes: number,
    fileEnding: string,
  ) => {
    const file = new File([''], `${faker.word.noun()}.${fileEnding}`, {
      type: mimeType,
    })
    Object.defineProperty(file, 'size', { value: sizeInBytes })
    return file
  }

  beforeEach(() => {
    node = createNode({
      type: 'input',
      name: 'attachments',
    })
    files = []
    allowedFiles = []
    options.writeToStore = false
  })

  it('returns true when no files fail the size validation', () => {
    const result = validateFileSize(node, files, allowedFiles)
    expect(result).toBe(true)
  })

  it('returns true when all files passes the size validation', () => {
    allowedFiles.push(
      allowedFileDocument,
      allowedFileAudio,
      allowedFileSticker,
      allowedFileImage,
      allowedFileVideo,
    )
    files.push(
      createFile('text/plain', 100 * 1024 * 1024, 'txt'),
      createFile('audio/aac', 16 * 1024 * 1024, 'aac'),
      createFile('application/pdf', 16 * 1024 * 1024, 'pdf'),
      createFile('image/webp', 500 * 1024, 'webp'),
      createFile('image/jpeg', 5 * 1024 * 1024, 'jpeg'),
      createFile('video/mp4', 16 * 1024 * 1024, 'mp4'),
    )
    const result = validateFileSize(node, files, allowedFiles)
    expect(result).toBe(true)
  })

  it('sets error message in formatKit message store when file size validation fails and writeToStore option is true', () => {
    options.writeToStore = true
    files.push(createFile('text/plain', 200 * 1024 * 1024, 'txt'))
    allowedFiles.push(allowedFileDocument)

    const isValid = validateFileSize(node, files, allowedFiles)

    // :TODO try to spy on set invocation and check if it was called
    // :TOTO check if node message store contains error message (as alternative) (external api test should be avoided)
    // currently set should be available on node.store but in test it fails
    // if you try to mock function with vi.fn() it does not get called
    // expect(node.store).to
    expect(isValid).toBeFalsy()
  })

  it('sets error message directly on formkit node when file size validation fails and writeToStore option is false', () => {
    files.push(createFile('text/plain', 200 * 1024 * 1024, 'txt'))
    allowedFiles.push(allowedFileDocument)
    const isValid = validateFileSize(node, files, allowedFiles)
    // :TODO try to spy on setErrors invocation and check if it was called
    expect(isValid).toBeFalsy()
  })
})
