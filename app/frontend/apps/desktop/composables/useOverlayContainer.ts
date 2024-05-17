// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { last, noop } from 'lodash-es'
import {
  computed,
  defineAsyncComponent,
  ref,
  onUnmounted,
  getCurrentInstance,
  onMounted,
  nextTick,
} from 'vue'

import {
  destroyComponent,
  pushComponent,
} from '#shared/components/DynamicInitializer/manage.ts'
import testFlags from '#shared/utils/testFlags.ts'

import type { AsyncComponentLoader, Component, Ref } from 'vue'

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
  beforeOpen?: () => Awaited<unknown>
  afterClose?: () => Awaited<unknown>
}

export type OverlayContainerType = 'dialog' | 'flyout'

export interface OverlayContainerMeta {
  mounted: Set<string>
  options: Map<string, OverlayContainerOptions>
  opened: Ref<Set<string>>
  lastFocusedElements: Record<string, HTMLElement>
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
  if (!overlayContainerMeta[type].opened.value.has(name)) return

  const options = getOverlayContainerOptions(type, name)

  await destroyComponent(type, name)

  overlayContainerMeta[type].opened.value.delete(name)

  if (options.afterClose) {
    await options.afterClose()
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
  // Close other open container from same type, before opening new one.
  const alreadyOpenedContainer = currentOverlayContainersOpen.value[type]
  if (alreadyOpenedContainer && alreadyOpenedContainer !== name) {
    await closeOverlayContainer(type, alreadyOpenedContainer)
  }

  if (overlayContainerMeta[type].opened.value.has(name))
    return Promise.resolve()

  const options = getOverlayContainerOptions(type, name)

  if (options.refocus) {
    overlayContainerMeta[type].lastFocusedElements[name] =
      document.activeElement as HTMLElement
  }

  overlayContainerMeta[type].opened.value.add(name)

  if (options.beforeOpen) {
    await options.beforeOpen()
  }

  const component = defineAsyncComponent(
    options.component as AsyncComponentLoader,
  )

  await pushComponent(type, name, component, props)

  return new Promise<void>((resolve) => {
    options.component().finally(() => {
      resolve()
      nextTick(() => {
        testFlags.set(`${name}.opened`)
      })
    })
  })
}

export const useOverlayContainer = (
  type: OverlayContainerType,
  options: OverlayContainerOptions,
) => {
  options.refocus ??= true

  overlayContainerMeta[type].options.set(
    options.name,
    options as OverlayContainerOptions,
  )

  const isOpened = computed(() =>
    overlayContainerMeta[type].opened.value.has(options.name),
  )

  const vm = getCurrentInstance()

  if (vm) {
    // Unmounted happens after setup, if component was unmounted so we need to add options again.
    // This happens mainly in storybook stories.
    onMounted(() => {
      overlayContainerMeta[type].mounted.add(options.name)
      overlayContainerMeta[type].options.set(
        options.name,
        options as OverlayContainerOptions,
      )
    })

    onUnmounted(async () => {
      overlayContainerMeta[type].mounted.delete(options.name)
      await closeOverlayContainer(type, options.name)
      // Was mounted during hmr.
      if (!overlayContainerMeta[type].mounted.has(options.name)) {
        overlayContainerMeta[type].options.delete(options.name)
      }
    })
  }

  const open = (props: Record<string, unknown> = {}) => {
    return openOverlayContainer(type, options.name, props)
  }

  const close = () => {
    return closeOverlayContainer(type, options.name)
  }

  const toggle = (props: Record<string, unknown> = {}) => {
    if (isOpened.value) {
      return closeOverlayContainer(type, options.name)
    }
    return openOverlayContainer(type, options.name, props)
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
    isOpened,
    name: options.name,
    open,
    close,
    toggle,
    prefetch,
  }
}
