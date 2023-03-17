// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { readonly, ref } from 'vue'

const isCustomLayout = ref(false)

export const useCustomLayout = () => {
  const setCustomLayout = (value: boolean) => {
    isCustomLayout.value = value
  }

  return {
    isCustomLayout: readonly(isCustomLayout),
    setCustomLayout,
  }
}
