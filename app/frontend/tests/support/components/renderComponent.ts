// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Plugin, Ref } from 'vue'
import { isRef, nextTick, ref, watchEffect, unref } from 'vue'
import type { Router, RouteRecordRaw } from 'vue-router'
import { createRouter, createWebHistory } from 'vue-router'
import type { MountingOptions } from '@vue/test-utils'
import { mount } from '@vue/test-utils'
import type { Matcher, RenderResult } from '@testing-library/vue'
import { render } from '@testing-library/vue'
import userEvent from '@testing-library/user-event'
import { merge, cloneDeep } from 'lodash-es'
import { plugin as formPlugin } from '@formkit/vue'
import { buildFormKitPluginConfig } from '@shared/form'
import applicationConfigPlugin from '@shared/plugins/applicationConfigPlugin'
import CommonIcon from '@shared/components/CommonIcon/CommonIcon.vue'
import CommonLink from '@shared/components/CommonLink/CommonLink.vue'
import CommonDateTime from '@shared/components/CommonDateTime/CommonDateTime.vue'
import CommonConfirmation from '@mobile/components/CommonConfirmation/CommonConfirmation.vue'
import CommonImageViewer from '@shared/components/CommonImageViewer/CommonImageViewer.vue'
import { imageViewerOptions } from '@shared/composables/useImageViewer'
import DynamicInitializer from '@shared/components/DynamicInitializer/DynamicInitializer.vue'
import { initializeWalker } from '@shared/router/walker'
import { initializeObjectAttributes } from '@mobile/object-attributes/initializeObjectAttributes'
import { i18n } from '@shared/i18n'
import buildIconsQueries from './iconQueries'
import buildLinksQueries from './linkQueries'
import { waitForNextTick } from '../utils'
import { cleanupStores, initializeStore } from './initializeStore'

// TODO: some things can be handled differently: https://test-utils.vuejs.org/api/#config-global

export interface ExtendedMountingOptions<Props> extends MountingOptions<Props> {
  router?: boolean
  routerRoutes?: RouteRecordRaw[]
  store?: boolean
  imageViewer?: boolean
  confirmation?: boolean
  form?: boolean
  formField?: boolean
  unmount?: boolean
  dialog?: boolean
  vModel?: {
    [prop: string]: unknown
  }
}

type UserEvent = ReturnType<(typeof userEvent)['setup']>

interface PageEvents extends UserEvent {
  debounced(fn: () => unknown, ms?: number): Promise<void>
}

export interface ExtendedRenderResult extends RenderResult {
  events: PageEvents
  queryAllByIconName(matcher: Matcher): SVGElement[]
  queryByIconName(matcher: Matcher): SVGElement | null
  getAllByIconName(matcher: Matcher): SVGElement[]
  getByIconName(matcher: Matcher): SVGElement
  findAllByIconName(matcher: Matcher): Promise<SVGElement[]>
  findByIconName(matcher: Matcher): Promise<SVGElement>
  getLinkFromElement(element: Element): HTMLAnchorElement
}

const plugins: (Plugin | [Plugin, ...unknown[]])[] = [
  (app) => {
    app.config.globalProperties.i18n = i18n
    app.config.globalProperties.$t = i18n.t.bind(i18n)
    app.config.globalProperties.__ = (source: string) => source
  },
]

const defaultWrapperOptions: ExtendedMountingOptions<unknown> = {
  global: {
    components: {
      CommonIcon,
      CommonLink,
      CommonDateTime,
    },
    stubs: {},
    plugins,
  },
}

interface MockedRouter extends Router {
  mockMethods(): void
  restoreMethods(): void
}

let routerInitialized = false
let router: MockedRouter

export const getTestRouter = () => router

const initializeRouter = (routes?: RouteRecordRaw[]) => {
  if (routerInitialized) return

  let localRoutes: RouteRecordRaw[] = [
    {
      name: 'Dashboard',
      path: '/',
      component: {
        template: 'Welcome to zammad.',
      },
    },
    {
      name: 'Example',
      path: '/example',
      component: {
        template: 'This is a example page.',
      },
    },
    {
      name: 'Error',
      path: '/:pathMatch(.*)*',
      component: {
        template: 'Error page',
      },
    },
  ]

  // Use only the default routes, if nothing was given.
  if (routes) {
    localRoutes = routes
  }

  router = createRouter({
    history: createWebHistory(),
    routes: localRoutes,
  }) as MockedRouter
  // cannot use "as const" here, because ESLint fails with obscure error :shrug:
  const methods = ['push', 'replace', 'back', 'go', 'forward'] as unknown as [
    'push',
  ]

  methods.forEach((name) => vi.spyOn(router, name))
  router.mockMethods = () => {
    methods.forEach((name) =>
      vi.mocked(router[name]).mockImplementation(() => Promise.resolve()),
    )
  }
  router.restoreMethods = () => {
    methods.forEach((name) => vi.mocked(router[name]).mockRestore())
  }

  plugins.push(router)
  plugins.push({
    install(app) {
      initializeWalker(app, router)
    },
  })

  defaultWrapperOptions.global ||= {}
  defaultWrapperOptions.global.stubs ||= {}
  Object.assign(defaultWrapperOptions.global.stubs, {
    RouterLink: false,
  })

  routerInitialized = true
}

let storeInitialized = false
export const initializePiniaStore = () => {
  if (storeInitialized) return
  const store = initializeStore()
  plugins.push({ install: store.install })
  storeInitialized = true
}

let formInitialized = false

const initializeForm = () => {
  if (formInitialized) return

  // TODO: needs to be extended, when we have app specific plugins/fields
  plugins.push([formPlugin, buildFormKitPluginConfig()])
  defaultWrapperOptions.shallow = false

  formInitialized = true
}

let applicationConfigInitialized = false

const initializeApplicationConfig = () => {
  if (applicationConfigInitialized) return

  initializePiniaStore()

  plugins.push(applicationConfigPlugin)

  applicationConfigInitialized = true
}

const wrappers = new Set<[ExtendedMountingOptions<any>, ExtendedRenderResult]>()

export const cleanup = () => {
  wrappers.forEach((wrapper) => {
    const [{ unmount = true }, view] = wrapper

    if (unmount) {
      view.unmount()
      wrappers.delete(wrapper)
    }
  })

  cleanupStores()
}

globalThis.cleanupComponents = cleanup

let dialogMounted = false

const mountDialog = () => {
  if (dialogMounted) return

  const Dialog = {
    components: { DynamicInitializer },
    template: '<DynamicInitializer name="dialog" />',
  } as any

  const { element } = mount(Dialog, defaultWrapperOptions)
  document.body.appendChild(element)

  dialogMounted = true
}

let imageViewerMounted = false

const mountImageViewer = () => {
  if (imageViewerMounted) return

  const ImageViewer = {
    components: { CommonImageViewer },
    template: '<CommonImageViewer />',
  } as any

  const { element } = mount(ImageViewer, defaultWrapperOptions)
  document.body.appendChild(element)

  imageViewerMounted = true
}

afterEach(() => {
  router?.restoreMethods()

  imageViewerOptions.value = {
    visible: false,
    index: 0,
    images: [],
  }
})

let confirmationMounted = false

const mountconfirmation = () => {
  if (confirmationMounted) return

  const Confirmation = {
    components: { CommonConfirmation },
    template: '<CommonConfirmation />',
  } as any

  const { element } = mount(Confirmation, defaultWrapperOptions)
  document.body.appendChild(element)

  confirmationMounted = true
}

const setupVModel = <Props>(wrapperOptions: ExtendedMountingOptions<Props>) => {
  const vModelProps: [string, Ref][] = []
  const vModelOptions = Object.entries(wrapperOptions?.vModel || {})

  for (const [prop, propDefault] of vModelOptions) {
    const reactiveValue = isRef(propDefault) ? propDefault : ref(propDefault)
    const props = (wrapperOptions.props ?? {}) as any
    props[prop] = unref(propDefault)
    props[`onUpdate:${prop}`] = (value: unknown) => {
      reactiveValue.value = value
    }

    vModelProps.push([prop, reactiveValue])

    wrapperOptions.props = props
  }

  const startWatchingModel = (view: ExtendedRenderResult) => {
    if (!vModelProps.length) return

    watchEffect(() => {
      const propsValues = vModelProps.reduce((acc, [prop, reactiveValue]) => {
        acc[prop] = reactiveValue.value
        return acc
      }, {} as Record<string, unknown>)

      view.rerender(propsValues)
    })
  }

  return {
    startWatchingModel,
  }
}

const renderComponent = <Props>(
  component: any,
  wrapperOptions: ExtendedMountingOptions<Props> = {},
): ExtendedRenderResult => {
  // Store and Router needs only to be initalized once for a test suit.
  if (wrapperOptions?.router) {
    initializeRouter(wrapperOptions?.routerRoutes)
  }
  if (wrapperOptions?.store) {
    initializePiniaStore()
  }
  if (wrapperOptions?.form) {
    initializeForm()
  }
  if (wrapperOptions?.dialog) {
    mountDialog()
  }
  if (wrapperOptions?.imageViewer) {
    mountImageViewer()
  }
  if (wrapperOptions?.confirmation) {
    mountconfirmation()
  }

  initializeApplicationConfig()
  initializeObjectAttributes()

  if (wrapperOptions?.form && wrapperOptions?.formField) {
    defaultWrapperOptions.props ||= {}

    // Reset the defult of 20ms for testing.
    defaultWrapperOptions.props.delay = 0
  }

  const { startWatchingModel } = setupVModel(wrapperOptions)

  const localWrapperOptions: ExtendedMountingOptions<Props> = merge(
    cloneDeep(defaultWrapperOptions),
    wrapperOptions,
  )

  // @testing-library consoles a warning, if these options are present
  delete localWrapperOptions.router
  delete localWrapperOptions.store

  const view = render(component, localWrapperOptions) as ExtendedRenderResult

  const events = userEvent.setup({
    advanceTimers(delay) {
      try {
        vi.advanceTimersByTime(delay)
        // eslint-disable-next-line no-empty
      } catch {}
    },
  })

  view.events = {
    ...events,
    async debounced(cb, ms) {
      vi.useFakeTimers()

      await cb()

      if (ms) {
        vi.advanceTimersByTime(ms)
      } else {
        vi.runAllTimers()
      }

      vi.useRealTimers()

      await waitForNextTick()
      await nextTick()
    },
  }

  Object.assign(view, buildIconsQueries(view.baseElement as HTMLElement))
  Object.assign(view, buildLinksQueries(view.baseElement as HTMLElement))

  wrappers.add([localWrapperOptions, view])

  startWatchingModel(view)

  return view
}

export default renderComponent
