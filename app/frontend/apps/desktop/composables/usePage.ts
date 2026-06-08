// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, shallowRef, watch, type ComputedRef, type Ref, type WatchHandle } from 'vue'

import useMetaTitle from '#shared/composables/useMetaTitle.ts'

import { useKeepAliveHooks } from './useKeepAliveHooks.ts'

interface PageOptions {
  metaTitle?: Ref<string> | ComputedRef<string>
  noTranslateMetaTitle?: Ref<boolean> | ComputedRef<boolean>
  onReactivate?: () => void
  onDeactivated?: () => void
}

export const usePage = (pageOptions: PageOptions = {}) => {
  const pageActive = shallowRef(true)

  const pageInactive = computed(() => !pageActive.value)

  const { metaTitle, noTranslateMetaTitle, onReactivate } = pageOptions

  let stopMetaTitleWatcher: WatchHandle | undefined

  const { setViewTitle } = useMetaTitle()

  useKeepAliveHooks({
    onReactivated() {
      onReactivate?.()
    },
    onActivated() {
      pageActive.value = true

      if (!metaTitle) return

      stopMetaTitleWatcher = watch(
        metaTitle,
        (newValue) => {
          if (noTranslateMetaTitle) setViewTitle(newValue, !noTranslateMetaTitle.value)
          else setViewTitle(newValue)
        },
        { immediate: true },
      )
    },
    onDeactivated() {
      pageActive.value = false
      stopMetaTitleWatcher?.()
      pageOptions.onDeactivated?.()
    },
  })

  return {
    pageActive,
    pageInactive,
  }
}
