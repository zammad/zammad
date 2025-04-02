// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { domFrom, waitForImagesToLoad } from '../dom.ts'

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

describe('waitForImagesToLoad', () => {
  it('resolves immediately if no images are present', async () => {
    const container = document.createElement('div')

    const promise = await waitForImagesToLoad(container)

    expect(promise).toEqual([])
  })

  it('resolves when all images load successfully', async () => {
    const container = document.createElement('div')
    const img1 = document.createElement('img')
    const img2 = document.createElement('img')
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

  it('rejects if any image fails to load', async () => {
    const container = document.createElement('div')
    const img1 = document.createElement('img')
    const img2 = document.createElement('img')
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
