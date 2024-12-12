// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useRoute } from 'vue-router'

import {
  closeOverlayContainer,
  getOpenedOverlayContainers,
  getOverlayContainerMeta,
  isOverlayContainerOpened,
  openOverlayContainer,
  useOverlayContainer,
  type OverlayContainerOptions,
} from '#desktop/composables/useOverlayContainer.ts'
import { getCurrentApp } from '#desktop/currentApp.ts'

const OVERLAY_CONTAINER_TYPE = 'flyout'

export const getOpenedFlyouts = () =>
  getOpenedOverlayContainers(OVERLAY_CONTAINER_TYPE)

export const isFlyoutOpened = (name?: string) =>
  isOverlayContainerOpened(OVERLAY_CONTAINER_TYPE, name)

export const getFlyoutMeta = () => {
  const overlayContainerMeta = getOverlayContainerMeta(OVERLAY_CONTAINER_TYPE)

  return {
    flyoutsOptions: overlayContainerMeta.options,
    openedFlyouts: overlayContainerMeta.opened,
  }
}

export const openFlyout = async (
  name: string,
  props: Record<string, unknown>,
  global: boolean = false,
) => {
  let currentName = name

  if (!global) {
    getCurrentApp().runWithContext(() => {
      const route = useRoute()

      currentName = `${name}_${route.path}`
    })
  }

  return openOverlayContainer(OVERLAY_CONTAINER_TYPE, currentName, props)
}

export const closeFlyout = async (name: string, global: boolean = false) => {
  let currentName = name

  if (!global) {
    getCurrentApp().runWithContext(() => {
      const route = useRoute()

      currentName = `${name}_${route.path}`
    })
  }

  return closeOverlayContainer(OVERLAY_CONTAINER_TYPE, currentName)
}

export const useFlyout = (options: OverlayContainerOptions) => {
  return useOverlayContainer(OVERLAY_CONTAINER_TYPE, options)
}
