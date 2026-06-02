<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useActiveElement, useLocalStorage, useWindowSize } from '@vueuse/core'
import { computed, nextTick, ref, watch, type MaybeRef } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types'
import type { AppSpecificTicketArticleType } from '#shared/entities/ticket-article/action/plugins/types.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import ResizeLine from '#desktop/components/ResizeLine/ResizeLine.vue'
import { useResizeLine } from '#desktop/components/ResizeLine/useResizeLine.ts'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'

interface Props {
  ticket: TicketById
  parentReachedBottomScroll: boolean
  newArticlePresent?: boolean
  createArticleType?: string | null
  ticketArticleTypes: AppSpecificTicketArticleType[]
  isTicketCustomer?: boolean
  hasInternalArticle?: boolean
  newArticleCount?: number
}

const props = defineProps<Props>()

defineEmits<{
  'show-article-form': [
    articleType: string,
    performReply: AppSpecificTicketArticleType['performReply'],
  ]
  'discard-form': []
  'scroll-into-view': []
}>()

const currentTicketArticleType = computed(() => {
  if (props.isTicketCustomer) return 'web'
  if (props.createArticleType && ['phone', 'web'].includes(props.createArticleType)) {
    return 'email'
  }

  return props.createArticleType
})

const allowedArticleTypes = computed(() => {
  return ['note', 'phone', currentTicketArticleType.value]
})

const availableArticleTypes = computed(() => {
  const availableArticleTypes = props.ticketArticleTypes.filter((type) =>
    allowedArticleTypes.value.includes(type.value),
  )

  return availableArticleTypes.map((type) => {
    return {
      articleType: type.value,
      label:
        currentTicketArticleType.value === type.value && !props.isTicketCustomer
          ? __('Reply to customer')
          : type.buttonLabel,
      icon: type.icon,
      performReply: (() =>
        type.performReply?.(props.ticket)) as AppSpecificTicketArticleType['performReply'],
    }
  })
})

const pinned = defineModel<boolean>('pinned')

const togglePinned = () => {
  pinned.value = !pinned.value
}

const articlePanel = ref<HTMLElement>()

// Scroll the new article panel into view whenever:
//   - an article is being added
//   - the panel is being unpinned
watch(
  () => [props.newArticlePresent, pinned.value],
  ([newArticlePresent, newPinned]) => {
    if (!newArticlePresent || newPinned) return

    nextTick(() => {
      // NB: Give editor a chance to initialize its height.
      setTimeout(() => {
        articlePanel.value?.scrollIntoView?.(true)
      }, 300)
    })
  },
)

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

// a11y keyboard navigation
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

const articleForm = ref<HTMLElement>()

const { reachedTop: articleFormReachedTop } = useElementScroll(articleForm as MaybeRef<HTMLElement>)

defineExpose({
  articlePanel,
})
</script>

<template>
  <div
    v-if="newArticlePresent"
    ref="articlePanel"
    class="relative mx-auto flex w-full flex-col"
    :class="{
      'h-fit max-w-6xl px-12 py-4': !pinned,
      'sticky bottom-0 z-20 self-end overflow-hidden border-t border-t-neutral-300 bg-neutral-50 backdrop-blur-2xs dark:border-t-gray-900 dark:bg-gray-500':
        pinned,
    }"
    :style="{
      height: pinned ? `${articlePanelHeight}px` : undefined,
      '--top-header-height': pinned ? '0px' : undefined, // In pinned mode we don't have the header as a overlapping element
    }"
    aria-labelledby="article-reply-form-title"
    role="complementary"
    :aria-expanded="!pinned"
    v-bind="$attrs"
  >
    <ResizeLine
      v-if="pinned"
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
    <div
      class="flex h-full grow flex-col"
      data-test-id="article-reply-stripes-panel"
      :class="{
        'bg-stripes relative z-0 rounded-xl outline-1 outline-blue-700 before:rounded-2xl':
          hasInternalArticle && !pinned,
        'border-stripes': hasInternalArticle && pinned,
      }"
    >
      <div
        class="isolate flex h-full grow flex-col"
        :class="{
          'rounded-xl border border-neutral-300 bg-neutral-50 dark:border-gray-900 dark:bg-gray-500':
            !pinned,
        }"
      >
        <div
          class="flex h-10 items-center p-3"
          :class="{
            'border-b border-b-transparent': pinned && articleFormReachedTop,
            'border-b border-b-neutral-300 dark:border-b-gray-900':
              pinned && !articleFormReachedTop,
          }"
        >
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
          class="grow px-3 pb-3"
          :class="{
            'overflow-y-auto': pinned,
            'my-1.25 px-4 pt-2': hasInternalArticle && pinned,
          }"
        />
      </div>
    </div>
  </div>
  <div
    v-else-if="newArticlePresent !== undefined"
    class="sticky bottom-0 z-20 row-start-3 grid w-full grid-cols-[minmax(min-content,1fr)_1fr_minmax(min-content,1fr)] py-1.5 backdrop-blur-2xs"
    :class="{
      'border-t border-t-neutral-100 bg-neutral-50/80 dark:border-t-gray-900 dark:bg-gray-500/80':
        !parentReachedBottomScroll,
    }"
  >
    <div v-if="newArticleCount && !parentReachedBottomScroll" class="relative w-fit self-center">
      <CommonButton
        v-tooltip="$t('Scroll to bottom')"
        class="mx-2.5"
        size="large"
        variant="subtle"
        icon="arrow-sm"
        @click="$emit('scroll-into-view')"
      />

      <CommonBadge
        size="xs"
        class="pointer-events-none absolute -top-1.5 block! max-w-10 min-w-4 truncate rounded-full! px-1! py-0! font-bold ltr:right-0.5 rtl:left-0.5"
        variant="highlight"
        :aria-label="$t('Unread messages count')"
        role="status"
      >
        {{ newArticleCount }}
      </CommonBadge>
    </div>

    <div class="col-start-2 flex items-center justify-center gap-2.5 self-center">
      <CommonButton
        v-for="button in availableArticleTypes"
        :key="button.articleType"
        :prefix-icon="button.icon"
        size="large"
        @click="$emit('show-article-form', button.articleType, button.performReply)"
      >
        {{ $t(button.label) }}
      </CommonButton>
    </div>
  </div>
</template>

<style scoped>
.border-stripes {
  position: relative;
  z-index: -10;
  background-color: var(--color-neutral-50);

  &::before {
    content: '';
    position: absolute;
    left: 0;
    top: 40px;
    bottom: 0;
    right: 0;
    border: 5px solid transparent;
    background-image: repeating-linear-gradient(
      45deg,
      var(--color-blue-400),
      var(--color-blue-400) 5px,
      var(--color-blue-700) 5px,
      var(--color-blue-700) 10px
    );
    background-position: -1px;
    background-attachment: fixed;
    mask:
      linear-gradient(white, white) padding-box,
      linear-gradient(white, white);
    mask-composite: exclude;
  }

  &::after {
    content: '';
    position: absolute;
    left: 0;
    top: 40px;
    bottom: 0;
    right: 0;
    outline: 1px solid var(--color-blue-700);
    outline-offset: -5px;
    pointer-events: none;
  }
}

[data-theme='dark'] .border-stripes {
  background-color: var(--color-gray-500);

  &::before {
    background-image: repeating-linear-gradient(
      45deg,
      var(--color-blue-700),
      var(--color-blue-700) 5px,
      var(--color-blue-900) 5px,
      var(--color-blue-900) 10px
    );
  }
}
</style>
