// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  computed,
  onActivated,
  onDeactivated,
  ref,
  watch,
  type ComputedRef,
  type Ref,
  type WatchHandle,
} from 'vue'

import useMetaTitle from '#shared/composables/useMetaTitle.ts'

interface PageOptions {
  pageActive?: Ref<boolean>
  metaTitle?: ComputedRef<string>
  onReactivate?: () => void
  onDeactivated?: () => void
}

export const usePage = (pageOptions: PageOptions = {}) => {
  const pageActive = pageOptions.pageActive || ref(true)

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

    pageOptions.onDeactivated?.()
  })

  return {
    pageActive,
    pageInactive,
  }
}
