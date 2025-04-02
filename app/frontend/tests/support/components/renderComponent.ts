// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

// import of these files takes 2.5 seconds for each test file!
// need to optimize this somehow

import { plugin as formPlugin } from '@formkit/vue'
import userEvent from '@testing-library/user-event'
import { render } from '@testing-library/vue'
import { mount } from '@vue/test-utils'
import { merge, cloneDeep } from 'lodash-es'
import { afterEach, vi } from 'vitest'
import {
  isRef,
  nextTick,
  ref,
  watchEffect,
  unref,
  type App,
  type Plugin,
  type Ref,
} from 'vue'
import { createRouter, createWebHistory } from 'vue-router'

import type { DependencyProvideApi } from '#tests/support/components/types.ts'

import CommonAlert from '#shared/components/CommonAlert/CommonAlert.vue'
import CommonBadge from '#shared/components/CommonBadge/CommonBadge.vue'
import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'
import CommonIcon from '#shared/components/CommonIcon/CommonIcon.vue'
import { provideIcons } from '#shared/components/CommonIcon/useIcons.ts'
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import CommonLink from '#shared/components/CommonLink/CommonLink.vue'
import DynamicInitializer from '#shared/components/DynamicInitializer/DynamicInitializer.vue'
import { initializeAppName } from '#shared/composables/useAppName.ts'
import { imageViewerOptions } from '#shared/composables/useImageViewer.ts'
import {
  setupCommonVisualConfig,
  type SharedVisualConfig,
} from '#shared/composables/useSharedVisualConfig.ts'
import { initializeTwoFactorPlugins } from '#shared/entities/two-factor/composables/initializeTwoFactorPlugins.ts'
import { buildFormKitPluginConfig } from '#shared/form/index.ts'
import { i18n } from '#shared/i18n.ts'
import applicationConfigPlugin from '#shared/plugins/applicationConfigPlugin.ts'
import tooltip from '#shared/plugins/directives/tooltip/index.ts'
import { setCurrentRouter } from '#shared/router/router.ts'
import { initializeWalker } from '#shared/router/walker.ts'
import type { AppName } from '#shared/types/app.ts'
import type { FormFieldTypeImportModules } from '#shared/types/form.ts'
import type { ImportGlobEagerOutput } from '#shared/types/utils.ts'

import { setCurrentApp } from '#desktop/currentApp.ts'
import { twoFactorConfigurationPluginLookup } from '#desktop/entities/two-factor-configuration/plugins/index.ts'
import desktopIconsAliases from '#desktop/initializer/desktopIconsAliasesMap.ts'
import mobileIconsAliases from '#mobile/initializer/mobileIconsAliasesMap.ts'

import { setTestState, waitForNextTick } from '../utils.ts'

import { getTestAppName } from './app.ts'
import buildIconsQueries from './iconQueries.ts'
import { cleanupStores, initializeStore } from './initializeStore.ts'
import buildLinksQueries from './linkQueries.ts'

import type { Matcher, RenderResult } from '@testing-library/vue'
import type { ComponentMountingOptions } from '@vue/test-utils'
import type { Router, RouteRecordRaw, NavigationGuard } from 'vue-router'

const appName = getTestAppName()

const isMobile = appName !== 'desktop'
const isDesktop = appName === 'desktop'

// not eager because we don't actually want to import all those components, we only need their names
const icons = isDesktop
  ? import.meta.glob('../../../apps/desktop/initializer/assets/*.svg')
  : import.meta.glob('../../../apps/mobile/initializer/assets/*.svg')

provideIcons(
  Object.keys(icons).map((icon) => [icon, { default: '' }]),
  isDesktop ? desktopIconsAliases : mobileIconsAliases,
)

// internal Vitest variable, ideally should check expect.getState().testPath, but it's not populated in 0.34.6 (a bug)
const { filepath } = (globalThis as any).__vitest_worker__ as any

let formFields: ImportGlobEagerOutput<FormFieldTypeImportModules>
let ConformationComponent: unknown
let initDefaultVisuals: () => void

// TODO: have a separate check for shared components
if (isMobile) {
  const [
    { default: CommonConfirmation },
    { initializeMobileVisuals },
    { mobileFormFieldModules },
  ] = await Promise.all([
    import('#mobile/components/CommonConfirmation/CommonConfirmation.vue'),
    import('#mobile/initializer/mobileVisuals.ts'),
    import('#mobile/form/index.ts'),
  ])
  initDefaultVisuals = initializeMobileVisuals
  ConformationComponent = CommonConfirmation
  formFields = mobileFormFieldModules
} else if (isDesktop) {
  const [{ initializeDesktopVisuals }, { desktopFormFieldModules }] =
    await Promise.all([
      import('#desktop/initializer/desktopVisuals.ts'),
      import('#desktop/form/index.ts'),
    ])
  initDefaultVisuals = initializeDesktopVisuals
  formFields = desktopFormFieldModules
} else {
  throw new Error(`Was not able to detect the app type from ${filepath} test.`)
}

// TODO: some things can be handled differently: https://test-utils.vuejs.org/api/#config-global

export interface ExtendedMountingOptions<Props>
  extends ComponentMountingOptions<Props> {
  router?: boolean
  routerRoutes?: RouteRecordRaw[]
  routerBeforeGuards?: NavigationGuard[]
  store?: boolean
  confirmation?: boolean
  form?: boolean
  provide?: DependencyProvideApi
  formField?: boolean
  unmount?: boolean
  dialog?: boolean
  flyout?: boolean
  app?: AppName
  vModel?: {
    [prop: string]: unknown
  }
  visuals?: SharedVisualConfig
  plugins?: Plugin[]
}

type UserEvent = ReturnType<(typeof userEvent)['setup']>

interface PageEvents extends UserEvent {
  debounced(fn: () => unknown, ms?: number): Promise<void>
}

export interface ExtendedRenderResult extends RenderResult {
  events: PageEvents
  router: Router
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
    setCurrentApp(app)
  },
]

const defaultWrapperOptions: ExtendedMountingOptions<unknown> = {
  global: {
    components: {
      CommonAlert,
      CommonIcon,
      CommonLink,
      CommonDateTime,
      CommonLabel,
      CommonBadge,
    },
    stubs: {},
    directives: { [tooltip.name]: tooltip.directive },
    plugins,
  },
}

interface MockedRouter extends Router {
  mockMethods(): void
  restoreMethods(): void
}

let routerInitialized = false
let router: MockedRouter
const history = createWebHistory(isDesktop ? '/desktop' : '/mobile')

export const getTestPlugins = () => [...plugins]
export const getTestRouter = () => router
export const getHistory = () => history

// cannot use "as const" here, because ESLint fails with obscure error :shrug:
const routerMethods = [
  'push',
  'replace',
  'back',
  'go',
  'forward',
] as unknown as ['push']

const ensureRouterSpy = () => {
  if (!router) return

  routerMethods.forEach((name) => vi.spyOn(router, name))
}

const initializeRouter = (
  routes?: RouteRecordRaw[],
  routerBeforeGuards?: NavigationGuard[],
) => {
  if (routerInitialized) {
    ensureRouterSpy()
    return
  }

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
    {
      name: 'search',
      path: '/search/:searchTerm?',
      component: {
        template: 'search',
      },
    },
  ]

  // Use only the default routes, if nothing was given.
  if (routes) {
    localRoutes = routes
  }

  router = createRouter({
    history,
    routes: localRoutes,
  }) as MockedRouter

  routerBeforeGuards?.forEach((guard) => router.beforeEach(guard))

  setCurrentRouter(router)

  ensureRouterSpy()

  router.mockMethods = () => {
    routerMethods.forEach((name) =>
      vi.mocked(router[name]).mockImplementation(() => Promise.resolve()),
    )
  }
  router.restoreMethods = () => {
    routerMethods.forEach((name) => {
      if (vi.isMockFunction(router[name])) {
        vi.mocked(router[name]).mockRestore()
      }
    })
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

  plugins.push([formPlugin, buildFormKitPluginConfig(undefined, formFields)])
  defaultWrapperOptions.shallow = false

  formInitialized = true
}

let applicationConfigInitialized = false

const initializeApplicationConfig = () => {
  if (applicationConfigInitialized) return

  initializePiniaStore()

  plugins.push(applicationConfigPlugin)

  if (isDesktop) {
    initializeTwoFactorPlugins(twoFactorConfigurationPluginLookup)
  }

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
  document.body.id = 'app'

  if (!document.getElementById('main-content')) {
    const mainElement = document.createElement('div')
    mainElement.id = 'main-content'
    document.body.insertAdjacentElement('afterbegin', mainElement)
  }

  dialogMounted = true
}

let flyoutMounted = false

const mountFlyout = () => {
  if (flyoutMounted) return

  const Flyout = {
    components: { DynamicInitializer },
    template: '<DynamicInitializer name="flyout" />',
  } as any

  const { element } = mount(Flyout, defaultWrapperOptions)
  document.body.appendChild(element)
  document.body.id = 'app'

  if (!document.getElementById('main-content')) {
    const mainElement = document.createElement('div')
    mainElement.id = 'main-content'
    document.body.insertAdjacentElement('afterbegin', mainElement)
  }

  flyoutMounted = true
}

setTestState({
  imageViewerOptions,
})

afterEach(() => {
  router?.restoreMethods()

  imageViewerOptions.value = {
    visible: false,
    index: 0,
    images: [],
  }
})

let confirmationMounted = false

const mountConfirmation = () => {
  if (confirmationMounted) return

  if (!ConformationComponent) {
    throw new Error('ConformationComponent is not defined.')
  }

  const Confirmation = {
    components: { CommonConfirmation: ConformationComponent },
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
      const propsValues = vModelProps.reduce(
        (acc, [prop, reactiveValue]) => {
          acc[prop] = reactiveValue.value
          return acc
        },
        {} as Record<string, unknown>,
      )

      view.rerender(propsValues)
    })
  }

  return {
    startWatchingModel,
  }
}

const mockProvide = (app: App, provideApi: DependencyProvideApi) => {
  provideApi.forEach((dependency) => {
    const [key, data] = dependency
    // App globals get reused in each test run we have to clear the provides in each test
    if (app._context.provides[key]) {
      app._context.provides[key] = data
    } else {
      app.provide(key, data)
    }
  })
}

const renderComponent = <Props>(
  component: any,
  wrapperOptions: ExtendedMountingOptions<Props> = {},
): ExtendedRenderResult => {
  initializeAppName(appName)

  // Store and Router needs only to be initalized once for a test suit.
  if (wrapperOptions.router) {
    initializeRouter(
      wrapperOptions.routerRoutes,
      wrapperOptions.routerBeforeGuards,
    )
  }
  if (wrapperOptions.store) {
    initializePiniaStore()
  }
  if (wrapperOptions.form) {
    initializeForm()
  }
  if (wrapperOptions.dialog) {
    mountDialog()
  }
  if (wrapperOptions.flyout) {
    mountFlyout()
  }
  if (wrapperOptions.confirmation) {
    mountConfirmation()
  }

  initializeApplicationConfig()

  if (wrapperOptions.visuals) {
    setupCommonVisualConfig(wrapperOptions.visuals)
  } else {
    initDefaultVisuals()
  }

  if (wrapperOptions.form && wrapperOptions.formField) {
    defaultWrapperOptions.props ||= {}

    // Reset the default of 20ms for testing.
    defaultWrapperOptions.props.delay = 0
  }

  if (wrapperOptions.plugins) {
    plugins.push(...wrapperOptions.plugins)

    delete wrapperOptions.plugins
  }

  if (wrapperOptions.provide) {
    plugins.push((app: App) => mockProvide(app, wrapperOptions.provide!))
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
      if (vi.isFakeTimers()) {
        vi.advanceTimersByTime(delay)
      }
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

  Object.defineProperty(view, 'router', {
    get() {
      return router
    },
    enumerable: true,
    configurable: true,
  })

  return view
}

export default renderComponent
