// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { createTestingPinia } from '@pinia/testing'

import { useHtmlLinks } from '../useHtmlLinks.ts'

const buildSampleElement = () => {
  const elem = document.createElement('div')

  elem.innerHTML = `some text
  <a href="http://example.com/asd" external>external</a>
  <a href="/desktop/test" internal>internal</a>
  <a href="/desktop/blank" blank target=_blank>blank</a>
  <a data-mention-user-id="123" mention>mention</a>
  her text`

  return elem
}

const routerPush = vi.fn()

vi.mock('vue-router', async () => {
  return {
    useRouter: () => {
      return {
        push: routerPush,
      }
    },
  }
})

describe('setupLinkHandlers', () => {
  createTestingPinia({ createSpy: vi.fn })

  it('replaces mention links with URLs to user profile', async () => {
    const elem = buildSampleElement()

    const { setupLinksHandlers } = useHtmlLinks('/desktop')

    setupLinksHandlers(elem)

    elem.querySelector<HTMLLinkElement>('a[mention]')?.click()

    expect(routerPush).toHaveBeenCalledWith('/users/123')
  })

  it('opens internal link via the router', () => {
    const elem = buildSampleElement()

    const { setupLinksHandlers } = useHtmlLinks('/desktop')

    setupLinksHandlers(elem)

    elem.querySelector<HTMLLinkElement>('a[internal]')?.click()

    expect(routerPush).toHaveBeenCalledWith('/test')
  })

  it('opens internal _blank link in a new tab', () => {
    vi.stubGlobal('open', vi.fn())
    const spy = vi.spyOn(window, 'open')

    const elem = buildSampleElement()

    const { setupLinksHandlers } = useHtmlLinks('/desktop')

    setupLinksHandlers(elem)

    elem.querySelector<HTMLLinkElement>('a[blank]')?.click()

    expect(spy).toHaveBeenCalledWith('/desktop/blank', '_blank')
  })

  it('opens external link directly', () => {
    vi.stubGlobal('open', vi.fn())
    const spy = vi.spyOn(window, 'open')

    const elem = buildSampleElement()

    const { setupLinksHandlers } = useHtmlLinks('/desktop')

    setupLinksHandlers(elem)

    elem.querySelector<HTMLLinkElement>('a[external]')?.click()

    expect(routerPush).not.toHaveBeenCalled()
    expect(spy).not.toHaveBeenCalled()
  })
})
