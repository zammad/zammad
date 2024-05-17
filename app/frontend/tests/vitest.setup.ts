// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { loadErrorMessages, loadDevMessages } from '@apollo/client/dev'
import '@testing-library/jest-dom/vitest'
import { toBeDisabled } from '@testing-library/jest-dom/matchers'
import { configure } from '@testing-library/vue'
import { expect } from 'vitest'
import * as matchers from 'vitest-axe/matchers'

import 'vitest-axe/extend-expect'
import { ServiceWorkerHelper } from '#shared/utils/testSw.ts'

import * as assertions from './support/assertions/index.ts'

// Zammad custom assertions: toBeAvatarElement, toHaveClasses, toHaveImagePreview, toHaveCurrentUrl

loadDevMessages()
loadErrorMessages()

vi.hoisted(() => {
  globalThis.__ = (source) => {
    return source
  }
})

window.sw = new ServiceWorkerHelper()

configure({
  testIdAttribute: 'data-test-id',
  asyncUtilTimeout: process.env.CI ? 30_000 : 1_000,
})

Object.defineProperty(window, 'fetch', {
  value: (path: string) => {
    throw new Error(`calling fetch on ${path}`)
  },
  writable: true,
  configurable: true,
})

class DOMRectList {
  length = 0

  // eslint-disable-next-line class-methods-use-this
  item = () => null;

  // eslint-disable-next-line class-methods-use-this
  [Symbol.iterator] = () => {
    //
  }
}

Object.defineProperty(Node.prototype, 'getClientRects', {
  value: new DOMRectList(),
})
Object.defineProperty(Element.prototype, 'scroll', { value: vi.fn() })
Object.defineProperty(Element.prototype, 'scrollBy', { value: vi.fn() })
Object.defineProperty(Element.prototype, 'scrollIntoView', { value: vi.fn() })

const descriptor = Object.getOwnPropertyDescriptor(
  HTMLImageElement.prototype,
  'src',
)!

Object.defineProperty(HTMLImageElement.prototype, 'src', {
  set(value) {
    descriptor.set?.call(this, value)
    this.dispatchEvent(new Event('load'))
  },
  get: descriptor.get,
})

Object.defineProperty(HTMLCanvasElement.prototype, 'getContext', {
  value: function getContext() {
    return {
      drawImage: (img: HTMLImageElement) => {
        this.__image_src = img.src
      },
      translate: vi.fn(),
      scale: vi.fn(),
    }
  },
})

Object.defineProperty(HTMLCanvasElement.prototype, 'toDataURL', {
  value: function toDataURL() {
    return this.__image_src
  },
})

// Mock IntersectionObserver feature by injecting it into the global namespace.
//   More info here: https://vitest.dev/guide/mocking.html#globals
const IntersectionObserverMock = vi.fn(() => ({
  disconnect: vi.fn(),
  observe: vi.fn(),
  takeRecords: vi.fn(),
  unobserve: vi.fn(),
}))
globalThis.IntersectionObserver = IntersectionObserverMock as any

require.extensions['.css'] = () => ({})

globalThis.requestAnimationFrame = (cb) => {
  setTimeout(cb, 0)
  return 0
}
globalThis.scrollTo = vi.fn<any>()
globalThis.matchMedia = (media: string) => ({
  matches: false,
  media,
  onchange: null,
  addListener: vi.fn(),
  removeListener: vi.fn(),
  dispatchEvent: vi.fn(),
  addEventListener: vi.fn(),
  removeEventListener: vi.fn(),
})

vi.mock(
  '#shared/components/CommonNotifications/useNotifications.ts',
  async () => {
    const { useNotifications: originalUseNotifications } =
      await vi.importActual<any>(
        '#shared/components/CommonNotifications/useNotifications.ts',
      )
    let notifications: any
    const useNotifications = () => {
      if (notifications) return notifications
      const result = originalUseNotifications()
      notifications = {
        notify: vi.fn(result.notify),
        notifications: result.notifications,
        removeNotification: vi.fn(result.removeNotification),
        clearAllNotifications: vi.fn(result.clearAllNotifications),
        hasErrors: vi.fn(result.hasErrors),
      }
      return notifications
    }

    return {
      useNotifications,
      default: useNotifications,
    }
  },
)

// don't rely on tiptap, because it's not supported in JSDOM
vi.mock(
  '#shared/components/Form/fields/FieldEditor/FieldEditorInput.vue',
  async () => {
    const { computed, defineComponent } = await import('vue')
    const component = defineComponent({
      name: 'FieldEditorInput',
      props: { context: { type: Object, required: true } },
      setup(props) {
        const value = computed({
          get: () => props.context._value,
          set: (value) => {
            props.context.node.input(value)
          },
        })

        return { value, name: props.context.node.name, id: props.context.id }
      },
      template: `<textarea :id="id" :name="name" v-model="value" />`,
    })
    return { __esModule: true, default: component }
  },
)

// mock vueuse because of CommonDialog, it uses usePointerSwipe
// that is not supported in JSDOM
vi.mock('@vueuse/core', async () => {
  const mod =
    await vi.importActual<typeof import('@vueuse/core')>('@vueuse/core')
  return {
    ...mod,
    usePointerSwipe: vi
      .fn()
      .mockReturnValue({ distanceY: 0, isSwiping: false }),
  }
})

beforeEach((context) => {
  context.skipConsole = false

  if (!vi.isMockFunction(console.warn)) {
    vi.spyOn(console, 'warn').mockClear()
  } else {
    vi.mocked(console.warn).mockClear()
  }

  if (!vi.isMockFunction(console.error)) {
    vi.spyOn(console, 'error').mockClear()
  } else {
    vi.mocked(console.error).mockClear()
  }
})

afterEach((context) => {
  // we don't import it from `renderComponent`, because renderComponent may not be called
  // and it doesn't make sense to import everything from it
  if ('cleanupComponents' in globalThis) {
    globalThis.cleanupComponents()
  }

  if (context.skipConsole !== true) {
    expect(
      console.warn,
      'there were no warning during test',
    ).not.toHaveBeenCalled()
    expect(
      console.error,
      'there were no errors during test',
    ).not.toHaveBeenCalled()
  }
})

// Import the matchers for accessibility testing with aXe.
expect.extend(matchers)
expect.extend(assertions)
// expect.extend(domMatchers)

expect.extend({
  // allow aria-disabled in toBeDisabled
  toBeDisabled(received, ...args) {
    if (received instanceof Element) {
      const attr = received.getAttribute('aria-disabled')
      if (!this.isNot && attr === 'true') {
        return { pass: true, message: () => '' }
      }
      if (this.isNot && attr === 'true') {
        // pass will be reversed and it will fail
        return { pass: true, message: () => 'should not have "aria-disabled"' }
      }
    }
    return (toBeDisabled as any).call(this, received, ...args)
  },
})

process.on('uncaughtException', (e) => console.log('Uncaught Exception', e))
process.on('unhandledRejection', (e) => console.log('Unhandled Rejection', e))

declare module 'vitest' {
  interface TestContext {
    skipConsole: boolean
  }

  // eslint-disable-next-line @typescript-eslint/no-empty-interface
  // interface Assertion<T> extends TestingLibraryMatchers<null, T> {}
}

declare module 'vitest' {
  // eslint-disable-next-line @typescript-eslint/no-empty-interface, @typescript-eslint/no-unused-vars
  interface Assertion<T> extends matchers.AxeMatchers {}
}

declare global {
  function cleanupComponents(): void
}
