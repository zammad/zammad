// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { domFrom, setAutoDirectionOnChildElements, waitForImagesToLoad } from '../dom.ts'

describe('domFrom', () => {
  const input = '<div>test</div>'

  it('parses dom and returns exact string representation', () => {
    const dom = domFrom(input)

    expect(dom.innerHTML).toBe(input)
  })

  it('parses dom and returns matching structure', () => {
    const dom = domFrom(input)

    expect(dom).toBeInstanceOf(HTMLElement)
    expect(dom.childNodes.length).toBe(1)

    const firstNode = dom.childNodes[0]

    expect(firstNode.textContent).toBe('test')
    expect(firstNode.childNodes[0]).toBeInstanceOf(Text)
  })
})

describe('setAutoDirectionOnChildElements', () => {
  it('sets dir="auto" on descendant elements only', () => {
    const container = domFrom(
      '<p>Intro</p>text<div><span>Nested</span></div><img src="inline.png">',
    )

    setAutoDirectionOnChildElements(container)

    expect(container).not.toHaveAttribute('dir')

    Array.from(container.children).forEach((child) => {
      expect(child).toHaveAttribute('dir', 'auto')
    })

    expect(container.querySelector('span')).toHaveAttribute('dir', 'auto')
  })
})

describe('waitForImagesToLoad', () => {
  const pendingImage = (source = 'pending.png') => {
    const image = document.createElement('img')
    image.setAttribute('src', source)
    Object.defineProperty(image, 'complete', { value: false })
    return image
  }

  it('resolves immediately if no images are present', async () => {
    const container = document.createElement('div')

    const promise = await waitForImagesToLoad(container)

    expect(promise).toEqual([])
  })

  it('resolves when all images load successfully', async () => {
    const container = document.createElement('div')
    const img1 = pendingImage()
    const img2 = pendingImage()
    container.appendChild(img1)
    container.appendChild(img2)

    const loadEvent = new Event('load')

    setTimeout(() => {
      img1.dispatchEvent(loadEvent)
      img2.dispatchEvent(loadEvent)
    }, 0)

    const promises = await waitForImagesToLoad(container)

    expect(promises).toHaveLength(2)
    promises.forEach((promise) => {
      expect(promise.status).toBe('fulfilled')
    })
  })

  it('does not wait for an image that has already finished loading', async () => {
    const container = document.createElement('div')
    const img = document.createElement('img')
    img.setAttribute('src', 'cached.png')
    // A cached image is complete before any handler is attached and fires no further event.
    Object.defineProperty(img, 'complete', { value: true })
    Object.defineProperty(img, 'naturalWidth', { value: 16 })
    container.appendChild(img)

    const promises = await waitForImagesToLoad(container)

    expect(promises).toHaveLength(1)
    expect(promises[0].status).toBe('fulfilled')
  })

  it.each(['missing', 'empty'])('does not wait for an image with a %s source', async (variant) => {
    const container = document.createElement('div')
    const img = document.createElement('img')
    if (variant === 'empty') img.setAttribute('src', '')
    container.appendChild(img)

    const promises = await waitForImagesToLoad(container)

    expect(promises).toHaveLength(1)
    expect(promises[0].status).toBe('rejected')
  })

  it('rejects if any image fails to load', async () => {
    const container = document.createElement('div')
    const img1 = pendingImage()
    const img2 = pendingImage()
    container.appendChild(img1)
    container.appendChild(img2)

    const loadEvent = new Event('error')
    const errorEvent = new Event('error')

    setTimeout(() => {
      img1.dispatchEvent(loadEvent)
      img2.dispatchEvent(errorEvent)
    }, 0)

    const promises = await waitForImagesToLoad(container)

    promises.forEach((promise) => {
      expect(promise.status).toBe('rejected')
    })
    expect(promises).toHaveLength(2)
  })
})
