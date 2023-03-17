// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { waitForAnimationFrame } from '@shared/utils/helpers'
import { onMounted, ref } from 'vue'

export const useArticleToggleMore = () => {
  const MIN_HEIGHT = 60
  const MAX_HEIGHT = 320
  let heightActual = 0
  let heightHidden = 0

  const bubbleElement = ref<HTMLElement>()
  const hasShowMore = ref(true)
  const shownMore = ref(false)

  const getSignatureMarker = (element: HTMLElement): HTMLElement | null => {
    const marker = element.querySelector('.js-signatureMarker') as HTMLElement
    if (marker) return marker

    return element.querySelector('div [data-signature=true]')
  }

  const setHeight = async () => {
    if (!bubbleElement.value) return

    const styles = bubbleElement.value.style
    styles.height = ''

    await waitForAnimationFrame()

    // it's possible it was remounted somehow
    if (!bubbleElement.value) return

    const height = bubbleElement.value.clientHeight

    heightActual = height

    const signatureMarker = getSignatureMarker(bubbleElement.value)

    const offsetTop = signatureMarker?.offsetTop || 0

    if (offsetTop > 0 && offsetTop < MAX_HEIGHT) {
      heightHidden = offsetTop < MIN_HEIGHT ? MIN_HEIGHT : offsetTop
      hasShowMore.value = true
    } else if (height > MAX_HEIGHT) {
      heightHidden = MAX_HEIGHT
      hasShowMore.value = true
    } else {
      hasShowMore.value = false
      heightHidden = 0
    }

    if (heightHidden) {
      styles.height = `${heightHidden}px`
    }
  }

  onMounted(async () => {
    if (!bubbleElement.value) return

    await setHeight()
  })

  const toggleShowMore = () => {
    if (!bubbleElement.value) return

    shownMore.value = !shownMore.value

    const styles = bubbleElement.value.style

    styles.transition = 'height 0.3s ease-in-out'
    styles.height = shownMore.value
      ? `${heightActual + 10}px`
      : `${heightHidden}px`

    const ontransitionend = () => {
      styles.transition = ''
      bubbleElement.value?.removeEventListener('transitionend', ontransitionend)
    }

    bubbleElement.value?.addEventListener('transitionend', ontransitionend)
  }

  return {
    toggleShowMore,
    hasShowMore,
    shownMore,
    bubbleElement,
  }
}
