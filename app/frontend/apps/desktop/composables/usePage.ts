// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import {
  computed,
  onActivated,
  onDeactivated,
  ref,
  watch,
  type ComputedRef,
  type WatchHandle,
} from 'vue'

import useMetaTitle from '#shared/composables/useMetaTitle.ts'

interface PageOptions {
  metaTitle?: ComputedRef<string>
  onReactivate?: () => void
}

export const usePage = (pageOptions: PageOptions) => {
  const pageActive = ref(true)

  const pageInactive = computed(() => !pageActive.value)

  const { metaTitle, onReactivate } = pageOptions

  let stopMetaTitleWatcher: WatchHandle | undefined

  const { setViewTitle } = useMetaTitle()

  onActivated(() => {
    // When it's already true, it means it's the first time, because onActivated is also called on the
    // first mount.
    if (pageActive.value !== true) {
      onReactivate?.()
    }

    pageActive.value = true

    if (metaTitle) {
      stopMetaTitleWatcher = watch(
        metaTitle,
        (newValue) => {
          setViewTitle(newValue)
        },
        { immediate: true },
      )
    }
  })

  onDeactivated(() => {
    pageActive.value = false

    stopMetaTitleWatcher?.()
  })

  return {
    pageActive,
    pageInactive,
  }
}
