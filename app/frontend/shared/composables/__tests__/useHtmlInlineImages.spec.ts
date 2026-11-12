// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createPinia, setActivePinia } from 'pinia'
import { describe, expect, vi } from 'vitest'
import { ref } from 'vue'

import type { ImageViewerFile } from '#shared/composables/useImageViewer.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import { useHtmlInlineImages } from '../useHtmlInlineImages.ts'

const buildSampleElement = () => {
  const elem = document.createElement('div')

  elem.innerHTML = `some text <img src="nonexistant.jpg">another text`

  return elem
}

describe('populateInlineImages', () => {
  it('clears existing entries in inlineImages', () => {
    const inlineImages = ref<ImageViewerFile[]>([])
    inlineImages.value.push({ name: 'sample entry' })

    buildSampleElement()

    const { populateInlineImages } = useHtmlInlineImages(inlineImages, vi.fn())

    populateInlineImages(document.createElement('div'))

    expect(inlineImages.value.length).toBe(0)
  })

  it('adds images to inline images', () => {
    const inlineImages = ref<ImageViewerFile[]>([])

    const elem = buildSampleElement()

    const { populateInlineImages } = useHtmlInlineImages(inlineImages, vi.fn())

    populateInlineImages(elem)

    expect(inlineImages.value).toEqual([
      {
        inline: 'http://localhost:3000/nonexistant.jpg',
        name: '',
        type: 'image/jpeg',
      },
    ])
  })

  it('takes the type of an embedded image the viewer can show from its data URL, and of any other from its name', () => {
    setActivePinia(createPinia())

    useApplicationStore().config['active_storage.content_types_allowed_inline'] = [
      'image/png',
      'image/jpeg',
      'image/webp',
    ]

    const inlineImages = ref<ImageViewerFile[]>([])

    const elem = document.createElement('div')

    elem.innerHTML = `<img src="data:image/jpeg;base64,/9j/4AAQ"><img src="data:image/webp;base64,UklGRg=="><img src="data:image/svg+xml;base64,PHN2Zy8+"><img src="data:image/bmp;base64,Qk0=" alt="scan.jpg"><img src="/api/v1/attachments/1" alt="scan.jpeg"><img src="/api/v1/attachments/2">`

    const { populateInlineImages } = useHtmlInlineImages(inlineImages, vi.fn())

    populateInlineImages(elem)

    expect(inlineImages.value.map(({ type }) => type)).toEqual([
      'image/jpeg',
      'image/webp',
      'image/png',
      'image/jpeg',
      'image/jpeg',
      'image/png',
    ])
  })

  it('adds onclick callback to images', () => {
    const inlineImages = ref<ImageViewerFile[]>([])

    const elem = buildSampleElement()

    const mockedCallback = vi.fn()

    const { populateInlineImages } = useHtmlInlineImages(inlineImages, mockedCallback)

    populateInlineImages(elem)

    elem.querySelector('img')?.click()

    expect(mockedCallback).toHaveBeenCalledWith(0)
  })
})
