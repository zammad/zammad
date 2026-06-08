<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useActiveElement, useLocalStorage, useWindowSize } from '@vueuse/core'
import { computed, ref } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import ResizeLine from '#desktop/components/ResizeLine/ResizeLine.vue'
import { useResizeLine } from '#desktop/components/ResizeLine/useResizeLine.ts'

interface Props {
  hasInternalArticle?: boolean
}

defineProps<Props>()

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

const articlePanel = ref<HTMLElement>()

defineExpose({ articlePanel })
</script>

<template>
  <div
    ref="articlePanel"
    class="mx-auto flex w-full flex-col overflow-hidden border-t border-t-neutral-300 bg-neutral-50 backdrop-blur-2xs dark:border-t-gray-900 dark:bg-gray-500"
    :style="{
      height: `${articlePanelHeight}px`,
      '--top-header-height': '0px',
    }"
  >
    <ResizeLine
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
    <div class="flex h-10 shrink-0 border-b border-b-neutral-300 dark:border-b-gray-900">
      <div class="mx-auto flex w-full max-w-6xl items-center px-12">
        <CommonLabel
          id="article-reply-form-title"
          class="text-stone-200 ltr:mr-auto rtl:ml-auto dark:text-neutral-500"
          tag="h2"
          size="small"
        >
          {{ $t('Reply') }}
        </CommonLabel>
        <CommonButton
          v-tooltip="$t('Discard unsaved reply')"
          class="text-red-500 ltr:mr-2 rtl:ml-2"
          variant="none"
          icon="trash"
          @click="$emit('discard-form')"
        />
        <CommonButton
          v-tooltip="$t('Unpin this panel')"
          icon="pin"
          variant="neutral"
          size="small"
          @click="$emit('toggle-pin')"
        />
      </div>
    </div>
    <div class="flex min-h-0 grow flex-col overflow-y-auto">
      <div class="mx-auto flex w-full max-w-6xl grow flex-col px-12 py-4">
        <div
          class="flex grow flex-col"
          data-test-id="article-reply-stripes-panel"
          :class="{
            'bg-stripes relative z-0 rounded-xl outline-1 outline-blue-700 before:rounded-2xl':
              hasInternalArticle,
          }"
        >
          <div
            class="isolate flex grow flex-col rounded-xl border border-neutral-300 bg-neutral-50 dark:border-gray-900 dark:bg-gray-500"
          >
            <div id="ticketArticleReplyFormPinned" class="grow p-3" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
