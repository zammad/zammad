// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { useElementScroll } from '#desktop/composables/useElementScroll.ts'

describe('useElementScroll', () => {
  let container: HTMLDivElement

  beforeEach(() => {
    container = document.createElement('div')
    container.style.height = '2000px'
    container.style.overflow = 'auto'
    document.body.appendChild(container)

    const content = document.createElement('div')
    content.style.height = '500px'
    container.appendChild(content)
  })

  afterEach(() => {
    document.body.removeChild(container)
  })

  it.todo('detects scrolling down', async () => {
    const { isScrollingDown } = useElementScroll(ref(container))
    container.scrollTop = 100 // Scroll down
    container.dispatchEvent(new Event('scroll'))
    expect(isScrollingDown.value).toBe(true)
  })

  it.todo('detects scrolling up', async () => {
    const { isScrollingDown } = useElementScroll(ref(container))
    container.scrollTop = 100 // Scroll down
    container.dispatchEvent(new Event('scroll'))
    expect(isScrollingDown.value).toBe(true)
  })

  it.todo('detects scrolling after start threshold', async () => {})

  it('detects reaching top', async () => {
    const { reachedTop } = useElementScroll(ref(container))
    container.scrollTop = 500
    container.scrollTop = 0
    container.dispatchEvent(new Event('scroll'))
    expect(reachedTop.value).toBe(true)
  })

  it('detects reaching bottom', async () => {
    const { reachedBottom } = useElementScroll(ref(container))
    container.scrollTop = container.clientHeight
    container.dispatchEvent(new Event('scroll'))
    expect(reachedBottom.value).toBe(true)
  })
})
