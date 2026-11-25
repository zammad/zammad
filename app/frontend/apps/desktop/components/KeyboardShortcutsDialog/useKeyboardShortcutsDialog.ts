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
  // The user menu stays reachable by its shortcut while the dialog is open.
  if (isDialogOpened(KEYBOARD_SHORTCUTS_DIALOG_NAME)) return

  return openDialog(KEYBOARD_SHORTCUTS_DIALOG_NAME, {}, true)
}

export const toggleKeyboardShortcutsDialog = () => {
  if (isDialogOpened(KEYBOARD_SHORTCUTS_DIALOG_NAME))
    return closeDialog(KEYBOARD_SHORTCUTS_DIALOG_NAME, true)

  return openKeyboardShortcutsDialog()
}

// This should only be called once from AppDesktop.vue
export const initializeKeyboardShortcutsDialog = () => {
  // The dialog is shown on every route, so it would stay open over the login after a logout.
  watch(toRef(useAuthenticationStore(), 'authenticated'), (authenticated) => {
    if (!authenticated) closeDialog(KEYBOARD_SHORTCUTS_DIALOG_NAME, true)
  })

  useDialog({
    name: KEYBOARD_SHORTCUTS_DIALOG_NAME,
    global: true,
    component: () => import('./KeyboardShortcutsDialog.vue'),
  })
}
