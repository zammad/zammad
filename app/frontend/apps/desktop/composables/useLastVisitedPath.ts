// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

// Remember the last visited path of a section, so its permanent, kept-alive
//   sidebar entry can return you to where you were instead of the section root
//   (used by the knowledge base and personal settings sections). The default is
//   returned until a path is remembered — an empty string means "nothing yet".
export const useLastVisitedPath = (defaultPath = '') => {
  const previousPath = ref(defaultPath)

  const rememberPath = (path: string) => {
    previousPath.value = path
  }

  return { previousPath, rememberPath }
}
