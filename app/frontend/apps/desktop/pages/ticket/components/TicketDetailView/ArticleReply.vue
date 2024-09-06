<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useActiveElement, useLocalStorage, useWindowSize } from '@vueuse/core'
import { computed, nextTick, ref, watch, type MaybeRef } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types'
import type { AppSpecificTicketArticleType } from '#shared/entities/ticket-article/action/plugins/types.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import type { ButtonVariant } from '#shared/types/button.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useMainLayoutContainer } from '#desktop/components/layout/composables/useMainLayoutContainer.ts'
import ResizeLine from '#desktop/components/ResizeLine/ResizeLine.vue'
import { useResizeLine } from '#desktop/components/ResizeLine/useResizeLine.ts'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'

interface Props {
  ticket: TicketById
  newArticlePresent?: boolean
  createArticleType?: string | null
  ticketArticleTypes: AppSpecificTicketArticleType[]
  isTicketCustomer?: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'show-article-form': [articleType: string, performReply: void]
}>()

const currentTicketArticleType = computed(() => {
  if (props.isTicketCustomer) return 'web'
  if (props.createArticleType === 'phone') return 'email'
  return props.createArticleType
})

const allowedArticleTypes = computed(() => {
  return ['note', 'phone', currentTicketArticleType.value]
})

const availableArticleTypes = computed(() => {
  const availableArticleTypes = props.ticketArticleTypes.filter((type) =>
    allowedArticleTypes.value.includes(type.value),
  )

  const hasEmail = availableArticleTypes.some((type) => type.value === 'email')

  let primaryTicketArticleType = currentTicketArticleType.value
  if (availableArticleTypes.length === 2) {
    primaryTicketArticleType = props.createArticleType
  }

  return availableArticleTypes.map((type) => {
    return {
      articleType: type.value,
      label:
        primaryTicketArticleType === type.value && hasEmail
          ? __('Add reply')
          : type.buttonLabel,
      icon: type.icon,
      variant:
        primaryTicketArticleType === type.value ||
        (type.value === 'phone' &&
          !hasEmail &&
          availableArticleTypes.length === 2)
          ? 'primary'
          : 'secondary',
      performReply: () => type.performReply?.(props.ticket),
    }
  })
})

const { node: mainLayoutContainerElement } = useMainLayoutContainer()

const { reachedBottom: mainLayoutReachedBottom } = useElementScroll(
  mainLayoutContainerElement as MaybeRef<HTMLElement>,
)

const { userId } = useSessionStore()

const pinned = useLocalStorage(`${userId}-article-reply-pinned`, false)

const togglePinned = () => {
  pinned.value = !pinned.value
}

const articlePanel = ref<HTMLElement>()

// Scroll the new article panel into view whenever:
//   - an article is being added
//   - the panel is being unpinned
watch(
  () => [props.newArticlePresent, pinned.value],
  ([newArticlePresent, pinned]) => {
    if (!newArticlePresent && pinned) return

    nextTick(() => {
      // NB: Give editor a chance to initialize its height.
      setTimeout(() => {
        articlePanel.value?.scrollIntoView?.(true)
      }, 100)
    })
  },
)

const DEFAULT_ARTICLE_PANEL_HEIGHT = 290
const MINIMUM_ARTICLE_PANEL_HEIGHT = 150

const articlePanelHeight = useLocalStorage(
  `${userId}-article-reply-height`,
  DEFAULT_ARTICLE_PANEL_HEIGHT,
)

const { height: screenHeight } = useWindowSize()

const articlePanelMaxHeight = computed(() => screenHeight.value / 2)

const resizeLine = ref<InstanceType<typeof ResizeLine>>()

const resizeCallback = (valueY: number) => {
  if (
    valueY >= articlePanelMaxHeight.value ||
    valueY < MINIMUM_ARTICLE_PANEL_HEIGHT
  )
    return

  articlePanelHeight.value = valueY
}

// a11y keyboard navigation
const activeElement = useActiveElement()

const handleKeyStroke = (e: KeyboardEvent, adjustment: number) => {
  if (
    !articlePanelHeight.value ||
    activeElement.value !== resizeLine.value?.resizeLine
  )
    return

  e.preventDefault()

  const newHeight = articlePanelHeight.value + adjustment

  if (newHeight >= articlePanelMaxHeight.value) return

  resizeCallback(newHeight)
}

const { startResizing } = useResizeLine(
  resizeCallback,
  resizeLine.value?.resizeLine,
  handleKeyStroke,
  { orientation: 'horizontal', offsetThreshold: 56 }, // bottom bar height in px
)

const resetHeight = () => {
  articlePanelHeight.value = DEFAULT_ARTICLE_PANEL_HEIGHT
}

const articleForm = ref<HTMLElement>()

const { reachedTop: articleFormReachedTop } = useElementScroll(
  articleForm as MaybeRef<HTMLElement>,
)
</script>

<template>
  <div
    v-if="newArticlePresent"
    ref="articlePanel"
    class="mx-auto w-full"
    :class="{
      'max-w-6xl px-12 py-4': !pinned,
      'sticky bottom-0 border-t border-t-neutral-300 bg-neutral-50 dark:border-t-gray-900 dark:bg-gray-500':
        pinned,
    }"
    :style="{
      height: pinned ? `${articlePanelHeight}px` : 'auto',
    }"
    role="complementary"
    :aria-expanded="!pinned"
  >
    <ResizeLine
      v-if="pinned"
      ref="resizeLine"
      class="group absolute h-3 w-full -translate-y-1.5 py-1"
      :label="$t('Resize article panel')"
      orientation="horizontal"
      :values="{
        max: articlePanelMaxHeight,
        min: MINIMUM_ARTICLE_PANEL_HEIGHT,
        current: articlePanelHeight,
      }"
      @mousedown-event="startResizing"
      @touchstart-event="startResizing"
      @dblclick="resetHeight"
    />

    <div
      class="flex h-full flex-col"
      :class="{
        'rounded-xl border border-neutral-300 bg-neutral-50 dark:border-gray-900 dark:bg-gray-500':
          !pinned,
      }"
    >
      <div
        class="flex h-10 items-center justify-between p-3"
        :class="{
          'bg-neutral-50 dark:bg-gray-500': pinned,
          'border-b border-b-transparent': articleFormReachedTop,
          'border-b border-b-neutral-300 dark:border-b-gray-900':
            !articleFormReachedTop,
        }"
      >
        <CommonLabel
          class="text-stone-200 dark:text-neutral-500"
          tag="h2"
          size="small"
        >
          {{ $t('Reply') }}
        </CommonLabel>
        <CommonButton
          v-tooltip="pinned ? $t('Unpin this panel') : $t('Pin this panel')"
          :icon="pinned ? 'pin' : 'pin-angle'"
          variant="neutral"
          size="small"
          @click="togglePinned"
        />
      </div>
      <div
        id="ticketArticleReplyForm"
        ref="articleForm"
        class="h-full px-3 pb-3"
        :class="{ 'overflow-y-auto': pinned }"
      ></div>
    </div>
  </div>
  <div
    v-else-if="newArticlePresent !== undefined"
    class="-:border-t-transparent sticky bottom-0 flex w-full justify-center gap-2.5 border-t py-1.5"
    :class="{
      'border-t-neutral-100 bg-neutral-50 dark:border-t-gray-900 dark:bg-gray-500':
        !mainLayoutReachedBottom,
    }"
  >
    <CommonButton
      v-for="button in availableArticleTypes"
      :key="button.articleType"
      :prefix-icon="button.icon"
      :variant="button.variant as ButtonVariant"
      size="large"
      @click="
        emit('show-article-form', button.articleType, button.performReply)
      "
    >
      {{ $t(button.label) }}
    </CommonButton>
  </div>
</template>
