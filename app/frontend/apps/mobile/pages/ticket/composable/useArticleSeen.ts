// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useIntersectionObserver } from '@vueuse/core'

import type { Ref } from 'vue'

export const useArticleSeen = (
  element: Ref<HTMLElement | undefined>,
  emit: (...args: any[]) => void,
) => {
  const observer = useIntersectionObserver(
    element,
    ([{ isIntersecting }]) => {
      if (isIntersecting) {
        emit('seen')
        observer.stop()
      }
    },
    { threshold: 0.4 },
  )
}
