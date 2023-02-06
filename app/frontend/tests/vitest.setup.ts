// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import '@testing-library/jest-dom'
import { configure } from '@testing-library/vue'
import * as matchers from 'vitest-axe/matchers'
import { expect } from 'vitest'
import 'vitest-axe/extend-expect'
import { ServiceWorkerHelper } from '@shared/utils/testSw'

global.__ = (source) => {
  return source
}

window.sw = new ServiceWorkerHelper()

configure({
  testIdAttribute: 'data-test-id',
  asyncUtilTimeout: 5000,
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

require.extensions['.css'] = () => ({})

vi.stubGlobal('requestAnimationFrame', (cb: () => void) => {
  setTimeout(cb, 0)
})

vi.stubGlobal('scrollTo', vi.fn())
vi.stubGlobal('matchMedia', (media: string) => ({
  matches: false,
  media,
  onchange: null,
  addEventListener: vi.fn(),
  removeEventListener: vi.fn(),
}))

vi.mock('@shared/components/CommonNotifications/composable', async () => {
  const { default: originalUseNotifications } = await vi.importActual<any>(
    '@shared/components/CommonNotifications/composable',
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
    default: useNotifications,
  }
})

// don't rely on tiptap, because it's not supported in JSDOM
vi.mock(
  '@shared/components/Form/fields/FieldEditor/FieldEditorInput.vue',
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

        return { value, name: props.context.name }
      },
      template: `<textarea :name="name" v-model="value" />`,
    })
    return { __esModule: true, default: component }
  },
)

// mock vueuse because of CommonDialog, it uses usePointerSwipe
// that is not supported in JSDOM
vi.mock('@vueuse/core', async () => {
  const mod = await vi.importActual<typeof import('@vueuse/core')>(
    '@vueuse/core',
  )
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
  // we don't import it from `renderComponent`, because it may renderComponent may not be called
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

declare module 'vitest' {
  interface TestContext {
    skipConsole: boolean
  }
}

declare global {
  function cleanupComponents(): void
}
