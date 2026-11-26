// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { toRef, watch } from 'vue'

import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import {
  closeDialog,
  isDialogOpened,
  openDialog,
  useDialog,
} from '#desktop/components/CommonDialog/useDialog.ts'

export const KEYBOARD_SHORTCUTS_DIALOG_NAME = 'keyboard-shortcuts'

export const openKeyboardShortcutsDialog = async () => {
  if (isDialogOpened(KEYBOARD_SHORTCUTS_DIALOG_NAME)) return

  return openDialog(KEYBOARD_SHORTCUTS_DIALOG_NAME, {}, true)
}

// Nothing to wait for while the dialog is closed.
export const closeKeyboardShortcutsDialog = () =>
  isDialogOpened(KEYBOARD_SHORTCUTS_DIALOG_NAME)
    ? closeDialog(KEYBOARD_SHORTCUTS_DIALOG_NAME, true)
    : undefined

export const toggleKeyboardShortcutsDialog = () =>
  isDialogOpened(KEYBOARD_SHORTCUTS_DIALOG_NAME)
    ? closeKeyboardShortcutsDialog()
    : openKeyboardShortcutsDialog()

// This should only be called once from AppDesktop.vue
export const initializeKeyboardShortcutsDialog = () => {
  // The dialog is shown on every route, so it would stay open over the login after a logout.
  watch(toRef(useAuthenticationStore(), 'authenticated'), (authenticated) => {
    if (!authenticated) closeKeyboardShortcutsDialog()
  })

  useDialog({
    name: KEYBOARD_SHORTCUTS_DIALOG_NAME,
    global: true,
    component: () => import('./KeyboardShortcutsDialog.vue'),
  })
}
