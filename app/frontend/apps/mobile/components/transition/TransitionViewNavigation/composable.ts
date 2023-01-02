// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'
import { ViewTransitions } from './types'

const viewTransition = ref<ViewTransitions>(ViewTransitions.Replace)

export const useViewTransition = () => {
  const setViewTransition = (newViewTransition: ViewTransitions) => {
    viewTransition.value = newViewTransition
  }

  return {
    setViewTransition,
    viewTransition,
  }
}
