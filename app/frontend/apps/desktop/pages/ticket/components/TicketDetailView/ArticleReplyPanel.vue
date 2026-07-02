<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useActiveElement, useLocalStorage, useWindowSize } from '@vueuse/core'
import { computed, nextTick, onMounted, ref, useTemplateRef } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import ResizeLine from '#desktop/components/ResizeLine/ResizeLine.vue'
import { useResizeLine } from '#desktop/components/ResizeLine/useResizeLine.ts'

interface Props {
  isPinned?: boolean
  hasInternalArticle?: boolean
  // Customers get a visible "Reply" heading inside the form (which carries the region's
  //  `aria-labelledby` id), so this panel omits its own sr-only heading for them.
  isTicketCustomer?: boolean
}

const props = defineProps<Props>()

defineEmits<{
  'discard-form': []
  'toggle-pin': []
}>()

const DEFAULT_ARTICLE_PANEL_HEIGHT = 290
const MINIMUM_ARTICLE_PANEL_HEIGHT = 150

const { userId } = useSessionStore()

const articlePanelHeight = useLocalStorage(
  `${userId}-article-reply-height`,
  DEFAULT_ARTICLE_PANEL_HEIGHT,
)

const { height: screenHeight } = useWindowSize()

const articlePanelMaxHeight = computed(() => screenHeight.value / 2)

const resizeLine = ref<InstanceType<typeof ResizeLine>>()

const resizeCallback = (valueY: number) => {
  if (valueY >= articlePanelMaxHeight.value || valueY < MINIMUM_ARTICLE_PANEL_HEIGHT) return
  articlePanelHeight.value = valueY
}

const activeElement = useActiveElement()

const handleKeyStroke = (e: KeyboardEvent, adjustment: number) => {
  if (!articlePanelHeight.value || activeElement.value !== resizeLine.value?.resizeLine) return
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

const articlePanel = useTemplateRef<HTMLElement>('article-panel')

onMounted(() => {
  if (props.isPinned) return

  nextTick(() => {
    // NB: Give editor a chance to initialize its height.
    setTimeout(() => {
      articlePanel.value?.scrollIntoView?.(true)
    }, 300)
  })
})
</script>

<template>
  <div
    ref="article-panel"
    class="mx-auto flex w-full flex-col"
    :class="{
      'overflow-hidden border-t border-t-neutral-300 bg-blue-200 dark:border-t-gray-900 dark:bg-gray-700':
        isPinned,
      'relative h-fit max-w-4xl py-4': !isPinned,
    }"
    :style="{
      height: isPinned ? `${articlePanelHeight}px` : undefined,
      '--top-header-height': isPinned ? '-1px' : undefined, // avoid joining with the header bottom border
    }"
  >
    <ResizeLine
      v-if="isPinned"
      ref="resizeLine"
      class="group absolute top-0 z-10 h-3 w-full"
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
    <h2 v-if="!isTicketCustomer" id="article-reply-form-title" class="sr-only">
      {{ $t('Reply') }}
    </h2>
    <div class="flex h-full min-h-0 grow flex-col">
      <div
        class="mx-auto flex h-full w-full max-w-4xl grow flex-col px-12"
        :class="{ 'py-3': isPinned }"
      >
        <div class="flex h-full grow flex-col" data-test-id="article-reply-stripes-panel">
          <!-- Positioning wrapper for the actions overlay. The reply box border + background live on
               the header and body inside the form: the header keeps the normal border (rounded
               top), the body continues it (public) or replaces it with the stripe (internal) — see
               useTicketEditForm. -->
          <div class="relative isolate flex h-full grow flex-col">
            <!-- Overlaid on the trailing end of the channel/visibility row. `top-2` matches the header's `py-2`,
                 and the height depends on the user permissions, so the actions are vertically aligned. -->
            <div
              class="absolute inset-e-3 top-2 z-20 flex items-center gap-2"
              :class="{
                'h-6': isTicketCustomer,
                'h-10': !isTicketCustomer,
              }"
            >
              <CommonButton
                v-tooltip="$t('Discard unsaved reply')"
                class="text-red-500"
                variant="none"
                icon="trash"
                @click="$emit('discard-form')"
              />
              <CommonButton
                v-tooltip="isPinned ? $t('Unpin this panel') : $t('Pin this panel')"
                :icon="isPinned ? 'pin' : 'pin-angle'"
                variant="neutral"
                size="small"
                @click="$emit('toggle-pin')"
              />
            </div>
            <div id="ticketArticleReplyForm" class="h-full grow" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
