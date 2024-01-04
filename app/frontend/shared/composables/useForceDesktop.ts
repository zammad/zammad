// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'

export const useForceDesktop = () => {
  const forceDesktopLocalStorage = useLocalStorage<boolean>(
    'forceDesktopApp',
    false,
    {
      writeDefaults: false,
    },
  )

  const forceDesktop = () => {
    forceDesktopLocalStorage.value = true
  }

  return {
    forceDesktopLocalStorage,
    forceDesktop,
  }
}
