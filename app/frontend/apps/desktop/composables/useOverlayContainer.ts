// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { last, noop } from 'lodash-es'
import SparkMD5 from 'spark-md5'
import {
  computed,
  defineAsyncComponent,
  ref,
  onUnmounted,
  getCurrentInstance,
  onMounted,
  nextTick,
  type AsyncComponentLoader,
  type Component,
  type Ref,
} from 'vue'
import { useRoute, type RouteLocationNormalizedLoadedGeneric } from 'vue-router'

import {
  destroyComponent,
  pushComponent,
} from '#shared/components/DynamicInitializer/manage.ts'
import testFlags from '#shared/utils/testFlags.ts'

export interface OverlayContainerOptions {
  name: string
  component: () => Promise<Component>
  prefetch?: boolean
  /**
   * If true, dialog will focus the element that opened it.
   * If dialog is opened without a user interaction, you should set it to false.
   * @default true
   */
  refocus?: boolean
  beforeOpen?: (uniqueId?: string) => Awaited<unknown>
  afterClose?: (uniqueId?: string) => Awaited<unknown>
  fullscreen?: boolean
  /**
   * If true, no page context will be added to the name, e.g. for confirmation dialogs.
   * @default false
   */
  global?: boolean
}

export type OverlayContainerType = 'dialog' | 'flyout'

export interface OverlayContainerMeta {
  mounted: Set<string>
  options: Map<string, OverlayContainerOptions>
  opened: Ref<Set<string>>
  lastFocusedElements: Record<string, HTMLElement>
}

export const getRouteIdentifier = (
  route: RouteLocationNormalizedLoadedGeneric,
) => {
  if (route.meta.pageKey) return route.meta.pageKey

  // If no params exists, just use the name.
  if (!route.params || !Object.keys(route.params).length) {
    return route.name ? String(route.name) : route.path
  }

  const paramHash = SparkMD5.hash(JSON.stringify(route.params))

  return `${String(route.name)}_${paramHash}`
}

const overlayContainerMeta: Record<OverlayContainerType, OverlayContainerMeta> =
  {
    dialog: {
      mounted: new Set<string>(),
      options: new Map<string, OverlayContainerOptions>(),
      opened: ref(new Set<string>()),
      lastFocusedElements: {},
    },
    flyout: {
      mounted: new Set<string>(),
      options: new Map<string, OverlayContainerOptions>(),
      opened: ref(new Set<string>()),
      lastFocusedElements: {},
    },
  }

export const getOpenedOverlayContainers = (type: OverlayContainerType) =>
  overlayContainerMeta[type].opened.value

export const isOverlayContainerOpened = (
  type: OverlayContainerType,
  name?: string,
) =>
  name
    ? overlayContainerMeta[type].opened.value.has(name)
    : overlayContainerMeta[type].opened.value.size > 0

export const currentOverlayContainersOpen = computed(() => {
  const openContainers: Partial<
    Record<OverlayContainerType, string | undefined>
  > = {}

  Object.keys(overlayContainerMeta).forEach((type) => {
    openContainers[type as OverlayContainerType] = last(
      Array.from(
        overlayContainerMeta[type as OverlayContainerType].opened.value,
      ),
    )
  })

  return openContainers
})

export const getOverlayContainerMeta = (type: OverlayContainerType) => {
  return {
    options: overlayContainerMeta[type].options,
    opened: overlayContainerMeta[type].opened,
  }
}

const getOverlayContainerOptions = (
  type: OverlayContainerType,
  name: string,
) => {
  const options = overlayContainerMeta[type].options.get(name)

  if (!options) {
    throw new Error(
      `Overlay container '${name}' from type '${type}' was not initialized with 'useOverlayContainer'.`,
    )
  }

  return options
}

export const closeOverlayContainer = async (
  type: OverlayContainerType,
  name: string,
) => {
  const [realName, uniqueId] = name.split(':')

  if (!overlayContainerMeta[type].opened.value.has(name)) return

  const options = getOverlayContainerOptions(type, realName)

  await destroyComponent(type, name)

  overlayContainerMeta[type].opened.value.delete(name)

  if (options.afterClose) {
    await options.afterClose(uniqueId)
  }

  const controllerElement =
    (document.querySelector(
      `[aria-haspopup="${type}"][aria-controls="${type}-${name}"]`,
    ) as HTMLElement | null) ||
    overlayContainerMeta[type].lastFocusedElements[name]
  if (controllerElement && 'focus' in controllerElement)
    controllerElement.focus({ preventScroll: true })

  nextTick(() => {
    testFlags.set(`${name}.closed`)
  })
}

export const openOverlayContainer = async (
  type: OverlayContainerType,
  name: string,
  props: Record<string, unknown>,
) => {
  const options = getOverlayContainerOptions(type, name)

  let uniqueName = name
  if (props.uniqueId) {
    uniqueName = `${name}:${props.uniqueId}`
  }

  if (options.refocus) {
    overlayContainerMeta[type].lastFocusedElements[uniqueName] =
      document.activeElement as HTMLElement
  }

  overlayContainerMeta[type].opened.value.add(uniqueName)

  if (options.beforeOpen) {
    await options.beforeOpen(props.uniqueId as string | undefined)
  }

  const component = defineAsyncComponent(
    options.component as AsyncComponentLoader,
  )

  await pushComponent(type, uniqueName, component, props)

  return new Promise<void>((resolve) => {
    options.component().finally(() => {
      resolve()
      nextTick(() => {
        testFlags.set(`${uniqueName}.opened`)
      })
    })
  })
}

export const useOverlayContainer = (
  type: OverlayContainerType,
  options: OverlayContainerOptions,
) => {
  const { name } = options

  const vm = getCurrentInstance()
  if (!vm) {
    throw new Error(
      `Overlay container '${name}' from type '${type}' was not initialized inside setup context.`,
    )
  }

  options.refocus ??= true

  const route = useRoute()

  const currentName = options.global
    ? name
    : `${name}_${getRouteIdentifier(route)}`

  overlayContainerMeta[type].options.set(currentName, options)

  const isOpened = computed(() =>
    overlayContainerMeta[type].opened.value.has(currentName),
  )

  // Unmounted happens after setup, if component was unmounted so we need to add options again.
  // This happens mainly in storybook stories.
  onMounted(() => {
    overlayContainerMeta[type].mounted.add(currentName)
    overlayContainerMeta[type].options.set(currentName, options)
  })

  onUnmounted(async () => {
    overlayContainerMeta[type].mounted.delete(currentName)
    await closeOverlayContainer(type, currentName)
    // Was mounted during hmr.
    if (!overlayContainerMeta[type].mounted.has(currentName)) {
      overlayContainerMeta[type].options.delete(currentName)
    }
  })

  const open = (props: Record<string, unknown> = {}) => {
    return openOverlayContainer(type, currentName, props)
  }

  const close = () => {
    return closeOverlayContainer(type, currentName)
  }

  const toggle = (props: Record<string, unknown> = {}) => {
    if (isOpened.value) {
      return closeOverlayContainer(type, currentName)
    }
    return openOverlayContainer(type, currentName, props)
  }

  let pendingPrefetch: Promise<unknown>
  const prefetch = async () => {
    if (pendingPrefetch) return pendingPrefetch
    pendingPrefetch = options.component().catch(noop)
    return pendingPrefetch
  }

  if (options.prefetch) {
    prefetch()
  }

  return {
    overlayContainerMeta,
    isOpened,
    name: currentName,
    open,
    close,
    toggle,
    prefetch,
  }
}
