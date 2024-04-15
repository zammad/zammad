// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  closeOverlayContainer,
  getOpenedOverlayContainers,
  getOverlayContainerMeta,
  isOverlayContainerOpened,
  openOverlayContainer,
  useOverlayContainer,
  type OverlayContainerOptions,
} from '#desktop/composables/useOverlayContainer.ts'

const OVERLAY_CONTAINER_TYPE = 'dialog'

export const getOpenedDialogs = () =>
  getOpenedOverlayContainers(OVERLAY_CONTAINER_TYPE)

export const isDialogOpened = (name?: string) =>
  isOverlayContainerOpened(OVERLAY_CONTAINER_TYPE, name)

export const getDialogMeta = () => {
  const overlayContainerMeta = getOverlayContainerMeta(OVERLAY_CONTAINER_TYPE)

  return {
    dialogsOptions: overlayContainerMeta.options,
    openedDialogs: overlayContainerMeta.opened,
  }
}

export const openDialog = async (
  name: string,
  props: Record<string, unknown>,
) => openOverlayContainer(OVERLAY_CONTAINER_TYPE, name, props)

export const closeDialog = async (name: string) =>
  closeOverlayContainer(OVERLAY_CONTAINER_TYPE, name)

export const useDialog = (options: OverlayContainerOptions) => {
  return useOverlayContainer(OVERLAY_CONTAINER_TYPE, options)
}
