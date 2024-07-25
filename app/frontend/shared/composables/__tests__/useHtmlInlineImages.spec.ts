// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { describe, expect, vi } from 'vitest'
import { ref } from 'vue'

import type { ImageViewerFile } from '#shared/composables/useImageViewer.ts'

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

  it('adds onclick callback to images', () => {
    const inlineImages = ref<ImageViewerFile[]>([])

    const elem = buildSampleElement()

    const mockedCallback = vi.fn()

    const { populateInlineImages } = useHtmlInlineImages(
      inlineImages,
      mockedCallback,
    )

    populateInlineImages(elem)

    elem.querySelector('img')?.click()

    expect(mockedCallback).toHaveBeenCalledWith(0)
  })
})
