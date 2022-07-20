// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import {
  destroyComponent,
  pushComponent,
} from '@shared/components/DynamicInitializer/manage'
import { noop } from 'lodash-es'
import type { AsyncComponentLoader, Component } from 'vue'
import {
  computed,
  defineAsyncComponent,
  ref,
  onUnmounted,
  getCurrentInstance,
  onMounted,
} from 'vue'

export interface DialogOptions {
  name: string
  component: () => Promise<Component>
  prefetch?: boolean
  beforeOpen?: () => Awaited<unknown>
  afterClose?: () => Awaited<unknown>
}

const dialogsOptions = new Map<string, DialogOptions>()
const dialogsOpened = ref(new Set<string>())

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

  dialogsOpened.value.add(name)

  if (options.beforeOpen) {
    await options.beforeOpen()
  }

  const component = defineAsyncComponent(
    options.component as AsyncComponentLoader,
  )

  await pushComponent('dialog', name, component, props)

  return new Promise<void>((resolve) => {
    options.component().finally(() => resolve())
  })
}

export const closeDialog = async (name: string) => {
  const options = getDialogOptions(name)

  await destroyComponent('dialog', name)

  dialogsOpened.value.delete(name)

  if (options.afterClose) {
    await options.afterClose()
  }
}

export const useDialog = (options: DialogOptions) => {
  dialogsOptions.set(options.name, options as DialogOptions)

  const isOpened = computed(() => dialogsOpened.value.has(options.name))

  const vm = getCurrentInstance()

  if (vm) {
    // unmounted happens after setup, if component was unmounted
    // so we need to add options again
    // this happens mainly in storybook stories
    onMounted(() => {
      dialogsOptions.set(options.name, options as DialogOptions)
    })

    onUnmounted(async () => {
      await closeDialog(options.name)
      dialogsOptions.delete(options.name)
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
