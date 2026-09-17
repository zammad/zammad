// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { onActivated, onMounted, ref } from 'vue'

import { waitForImagesToLoad } from '#shared/utils/dom.ts'
import { waitForAnimationFrame } from '#shared/utils/helpers.ts'

export const useArticleToggleMore = () => {
  const MIN_HEIGHT = 60
  const MAX_HEIGHT = 320
  let heightHidden = 0

  const bubbleElement = ref<HTMLDivElement>()
  const hasShowMore = ref(true)
  const shownMore = ref(false)

  // A hidden tab is detached from the document, where nothing has a height.
  let measureOnActivation = false

  const getSignatureMarker = (element: HTMLElement): HTMLElement | null => {
    const marker = element.querySelector('.js-signatureMarker') as HTMLElement
    if (marker) return marker

    return element.querySelector('div [data-signature=true]')
  }

  const setHeight = async () => {
    if (!bubbleElement.value) return

    const styles = bubbleElement.value.style

    await waitForAnimationFrame()

    // it's possible it was remounted somehow
    if (!bubbleElement.value) return

    if (!bubbleElement.value.isConnected) {
      measureOnActivation = true
      return
    }

    // The content height, whatever the element is constrained to right now: measuring this way
    // never shows the full content in between, e.g. when a translation replaces the body.
    const previousHeight = styles.height
    styles.height = 'auto'
    const height = bubbleElement.value.scrollHeight
    styles.height = previousHeight

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

    styles.height = heightHidden ? `${heightHidden}px` : ''
  }

  // Measures once the content, inline images included, is there; a swapped body calls it again.
  const recalculateHeight = async () => {
    if (!bubbleElement.value) return

    // Wait for inline images to load before calculating height
    // Resolved immediately if no images are present
    await waitForImagesToLoad(bubbleElement)

    await setHeight()

    if (shownMore.value && bubbleElement.value) bubbleElement.value.style.height = 'auto'
  }

  onMounted(recalculateHeight)

  onActivated(() => {
    if (!measureOnActivation) return

    measureOnActivation = false
    recalculateHeight()
  })

  const toggleShowMore = () => {
    if (!bubbleElement.value) return

    shownMore.value = !shownMore.value

    const styles = bubbleElement.value.style

    styles.height = shownMore.value ? 'auto' : `${heightHidden}px`
  }

  return {
    toggleShowMore,
    recalculateHeight,
    hasShowMore,
    shownMore,
    bubbleElement,
  }
}
