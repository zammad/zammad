// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { ComputedRef, UnwrapRef } from 'vue'
import { ref, watch } from 'vue'
import type { RouteLocationRaw } from 'vue-router'
import useMetaTitle from '@shared/composables/useMetaTitle'

export interface HeaderOptions {
  title?: string | ComputedRef<string>
  titleClass?: string | ComputedRef<string>
  backTitle?: string | ComputedRef<string>
  backUrl?: RouteLocationRaw | ComputedRef<RouteLocationRaw>
  actionTitle?: string | ComputedRef<string>
  onAction?(): unknown
}

export const headerOptions = ref<HeaderOptions>({})

const { setViewTitle } = useMetaTitle()

watch(
  () => headerOptions.value.title,
  (title) => title && setViewTitle(title),
)

export const useHeader = (options: HeaderOptions) => {
  headerOptions.value = options as UnwrapRef<HeaderOptions>
}
