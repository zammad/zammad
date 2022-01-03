// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import ViewTransitions from '@mobile/types/transition'
import { ref } from 'vue'

const viewTransition = ref<ViewTransitions>(ViewTransitions.REPLACE)

export default function useViewTransition() {
  function setViewTransition(newViewTransition: ViewTransitions) {
    viewTransition.value = newViewTransition
  }

  return {
    setViewTransition,
    viewTransition,
  }
}
