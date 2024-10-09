// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useScroll, useThrottleFn, whenever } from '@vueuse/core'
import { computed, type Ref, ref, type ShallowRef, watch } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'

import type ArticleList from '#desktop/pages/ticket/components/TicketDetailView/ArticleList.vue'
import TicketDetailTopBar from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TicketDetailTopBar.vue'

export const useArticleContainerScroll = (
  ticket: Ref<TicketById>,
  contentContainerElement: Readonly<ShallowRef<HTMLDivElement | null>>,
  articleListInstance: Readonly<
    ShallowRef<InstanceType<typeof ArticleList> | null>
  >,
  topBarInstance: Readonly<
    ShallowRef<InstanceType<typeof TicketDetailTopBar> | null>
  >,
) => {
  const THROTTLE_TIME = 250

  const { arrivedState } = useScroll(contentContainerElement, {
    eventListenerOptions: { passive: true },
  })

  const isHidingTicketDetails = ref(false)
  const isReachingBottom = ref(false)

  const previousPosition = ref(0)

  const reset = () => {
    isReachingBottom.value = false
    isHidingTicketDetails.value = false
    previousPosition.value = 0
  }

  const _isHoveringOnTopBar = ref(false)

  const isHoveringOnTopBar = computed({
    get: () => _isHoveringOnTopBar.value,
    set: (value) => {
      _isHoveringOnTopBar.value = value

      if (value) {
        isHidingTicketDetails.value = false
      }
    },
  })

  const handleScroll = useThrottleFn((event: Event) => {
    const container = event.target! as HTMLDivElement

    const { scrollHeight, clientHeight } = container

    const isScrollable = scrollHeight > clientHeight

    if (!isScrollable) return reset()

    const scrollTop = container.scrollTop ?? 0

    isReachingBottom.value = scrollTop + clientHeight < scrollHeight

    // If we keep the pointer on the top bar we do not want to hide the details if the user starts to scroll on the same time.
    if (!isHoveringOnTopBar.value) {
      isHidingTicketDetails.value =
        scrollTop > (topBarInstance.value?.$el.clientHeight ?? 0)
    }

    previousPosition.value = scrollTop
  }, THROTTLE_TIME)

  watch(
    () => arrivedState.bottom,
    (value) => {
      isReachingBottom.value = !value

      if (isHoveringOnTopBar.value) return

      isHidingTicketDetails.value = true
    },
  )

  whenever(
    () => arrivedState.top,
    () => {
      if (isHoveringOnTopBar.value) return

      isHidingTicketDetails.value = false
    },
  )

  watch(
    () => ticket.value?.id,
    () => {
      articleListInstance.value?.setDidInitialScroll(false)
    },
    { immediate: true },
  )

  watch(
    () => articleListInstance.value?.rows,
    async () => {
      if (articleListInstance.value?.didScrollInitially) return

      await articleListInstance.value?.scrollToArticle()

      articleListInstance.value?.setDidInitialScroll(true)

      // Normally handleScroll runs after we this, in some edge cases if it is not triggered we reset the states.
      reset()
    },
    { flush: 'post' },
  )

  // Handling scrolling to bottom if new article is added
  watch(
    () => articleListInstance.value?.rows,
    (newRows, oldRows) => {
      if (!newRows || !oldRows) return

      if (newRows.at(-1)?.key === oldRows.at(-1)?.key) return
      // article got removed
      if (newRows.at(-1)?.key === oldRows.at(-2)?.key) return
      // article got added
      articleListInstance.value?.scrollToArticle()
    },
  )

  return {
    handleScroll,
    isHoveringOnTopBar,
    isHidingTicketDetails,
    isReachingBottom,
  }
}
