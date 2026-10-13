// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// The editor is the largest lazy chunk of the app, so it is fetched on start
//   instead of on the first reply.
const loadEditor = () => import('#shared/components/Form/fields/FieldEditor/FieldEditorInput.vue')

export const preloadComponents = () => {
  loadEditor()
}
