// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { noop } from 'lodash-es'
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

import type { AsyncComponentLoader, Component } from 'vue'

interface DialogOptions {
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

const mounted = new Set<string>()
const dialogsOptions = new Map<string, DialogOptions>()
const dialogsOpened = ref(new Set<string>())
const lastFocusedElements: Record<string, HTMLElement> = {}

export const getOpenedDialogs = () => dialogsOpened.value

export const isDialogOpened = (name?: string) =>
  name ? dialogsOpened.value.has(name) : dialogsOpened.value.size > 0

export const getDialogMeta = () => {
  return {
    dialogsOptions,
    dialogsOpened,
  }
}

const getDialogOptions = (name: string) => {
  const options = dialogsOptions.get(name)

  if (!options) {
    throw new Error(`Dialog '${name}' was not initialized with 'useDialog'`)
  }

  return options
}

export const openDialog = async (
  name: string,
  props: Record<string, unknown>,
) => {
  if (dialogsOpened.value.has(name)) return Promise.resolve()

  const options = getDialogOptions(name)

  if (options.refocus) {
    lastFocusedElements[name] = document.activeElement as HTMLElement
  }

  dialogsOpened.value.add(name)

  if (options.beforeOpen) {
    await options.beforeOpen()
  }

  const component = defineAsyncComponent(
    options.component as AsyncComponentLoader,
  )

  await pushComponent('dialog', name, component, props)

  return new Promise<void>((resolve) => {
    options.component().finally(() => {
      resolve()
      nextTick(() => {
        testFlags.set(`${name}.opened`)
      })
    })
  })
}

export const closeDialog = async (name: string) => {
  if (!dialogsOpened.value.has(name)) return

  const options = getDialogOptions(name)

  await destroyComponent('dialog', name)

  dialogsOpened.value.delete(name)

  if (options.afterClose) {
    await options.afterClose()
  }

  const controllerElement =
    (document.querySelector(
      `[aria-haspopup="dialog"][aria-controls="dialog-${name}"]`,
    ) as HTMLElement | null) || lastFocusedElements[name]
  if (controllerElement && 'focus' in controllerElement)
    controllerElement.focus({ preventScroll: true })

  nextTick(() => {
    testFlags.set(`${name}.closed`)
  })
}

export const useDialog = (options: DialogOptions) => {
  options.refocus ??= true

  dialogsOptions.set(options.name, options as DialogOptions)

  const isOpened = computed(() => dialogsOpened.value.has(options.name))

  const vm = getCurrentInstance()

  if (vm) {
    // unmounted happens after setup, if component was unmounted
    // so we need to add options again
    // this happens mainly in storybook stories
    onMounted(() => {
      mounted.add(options.name)
      dialogsOptions.set(options.name, options as DialogOptions)
    })

    onUnmounted(async () => {
      mounted.delete(options.name)
      await closeDialog(options.name)
      // was mounted during hmr
      if (!mounted.has(options.name)) {
        dialogsOptions.delete(options.name)
      }
    })
  }

  const open = (props: Record<string, unknown> = {}) => {
    return openDialog(options.name, props)
  }

  const close = () => {
    return closeDialog(options.name)
  }

  const toggle = (props: Record<string, unknown> = {}) => {
    if (isOpened.value) {
      return closeDialog(options.name)
    }
    return openDialog(options.name, props)
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
