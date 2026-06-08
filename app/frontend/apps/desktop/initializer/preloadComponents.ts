// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// "Pre" Load editor on app start to be faster available
const loadEditor = () => import('#shared/components/Form/fields/FieldEditor/FieldEditorInput.vue')

// If loaded more components in the future
export const preloadComponents = () => {
  loadEditor()
}
