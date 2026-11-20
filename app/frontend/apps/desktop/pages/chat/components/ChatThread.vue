<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useResizeObserver } from '@vueuse/core'
import { computed, nextTick, onActivated, onMounted, ref, useTemplateRef, watch } from 'vue'

import CommonTranslateRenderer from '#shared/components/CommonTranslateRenderer/CommonTranslateRenderer.vue'

import CommonDivider from '#desktop/components/CommonDivider/CommonDivider.vue'
import CommonFloatingToolbar from '#desktop/components/CommonFloatingToolbar/CommonFloatingToolbar.vue'
import type { ChatThreadEntry } from '#desktop/entities/chat/types.ts'
import { isAgentMessage } from '#desktop/entities/chat/utils.ts'

import ChatMessageBubble from './ChatMessageBubble.vue'
import ChatThreadEnding from './ChatThreadEnding.vue'

import type { ChatFooterNote as ChatFooterNoteData } from './types.ts'

interface Props {
  entries: ChatThreadEntry[]
  // The page the customer started the chat on.
  url?: string | null
  isCustomerTyping?: boolean
  unreadMessageIds?: ReadonlySet<string>
  // How the conversation ended, after its last message.
  endingNote?: ChatFooterNoteData
}

const props = defineProps<Props>()

const emit = defineEmits<{
  // The button the agent used goes away at the end of the thread, with the focus they had in the window.
  leave: []
}>()

const isUnread = (entry: ChatThreadEntry) =>
  entry.kind === 'message' && Boolean(props.unreadMessageIds?.has(entry.id))

// The first in the thread rather than the first counted: one missed while the connection was down
//   is counted after newer ones.
const firstUnreadId = computed(() => props.entries.find(isUnread)?.id)

// Like the old interface: a time when more than two minutes passed since the message before.
const SHOW_TIME_AFTER_MS = 2 * 60 * 1000

const items = computed(() => {
  let previousTime: number | undefined

  return props.entries.map((entry, index) => {
    if (entry.kind === 'notice') return { entry, showTime: false, isFollowUp: false }

    const time = new Date(entry.message.createdAt).getTime()
    const showTime = previousTime === undefined || time - previousTime > SHOW_TIME_AFTER_MS

    previousTime = time

    // Messages one after another from the same side, with no time between them, sit closer
    //   together, unless the unread ones begin in between.
    const previous = props.entries[index - 1]
    const isFollowUp =
      !showTime &&
      entry.id !== firstUnreadId.value &&
      previous?.kind === 'message' &&
      isAgentMessage(previous.message) === isAgentMessage(entry.message)

    return { entry, showTime, isFollowUp }
  })
})

// The widget reports the pages of the customer unchecked, as typed by any client: only a single web
//   address becomes a link.
const isWebAddress = (text: string) => /^https?:\/\/\S+$/i.test(text)

// The customer's page opens apart from Zammad: no hold on its tab, no hint of its address.
const pageLinkProps = {
  size: 'xs',
  rel: 'noopener noreferrer',
  external: true,
  openInNewTab: true,
} as const

// The typing is the customer's, so it follows a message of theirs as closely.
const isTypingFollowUp = computed(() => {
  const last = props.entries.at(-1)

  return last?.kind === 'message' && !isAgentMessage(last.message)
})

const thread = useTemplateRef('thread')

const content = useTemplateRef('content')

// Like the old interface: a few pixels short of the end still count as the end.
const END_TOLERANCE_PX = 10

// Whether the agent reads the newest entry; one who scrolled up is reading what was said before.
const isAtEnd = ref(true)

// A message of the customer arrived below what the agent reads.
const hasNewBelow = ref(false)

// Rendered in the loop, so a list, of one at most.
const unreadDivider = useTemplateRef<HTMLElement[]>('unread-divider')

// How far the start of the unread messages is below the top of what the agent reads.
const firstUnreadOffset = () => {
  const element = thread.value

  const target = unreadDivider.value?.[0]

  if (!element || !target) return undefined

  const padding = Number.parseFloat(getComputedStyle(element).paddingTop) || 0

  return target.getBoundingClientRect().top - element.getBoundingClientRect().top - padding
}

// Sub-pixel offsets of a divider the button already brought to the top.
const AT_TOP_TOLERANCE_PX = 2

// Going there reads nothing, so once the agent is there or past it, the button goes on to the end.
const isFirstUnreadAhead = ref(false)

const measureFirstUnread = () => {
  isFirstUnreadAhead.value = (firstUnreadOffset() ?? 0) > AT_TOP_TOLERANCE_PX
}

let lastScrollTop = 0

// The sizes `remeasure` last saw, of the thread and of what it shows. A scroll event that finds
//   others comes before `remeasure` hears of them: it is not the agent leaving the end.
let knownSize = ''

const sizeOf = (element: HTMLElement) =>
  `${element.clientWidth}x${element.clientHeight}x${element.scrollHeight}`

const onScroll = () => {
  const element = thread.value

  // Out of the document, where the kept-alive page waits, a thread has no size and would be at its end.
  if (!element?.isConnected) return

  if (isAtEnd.value && knownSize && sizeOf(element) !== knownSize) return

  lastScrollTop = element.scrollTop

  isAtEnd.value =
    element.scrollHeight - element.scrollTop - element.clientHeight <= END_TOLERANCE_PX

  if (isAtEnd.value) hasNewBelow.value = false

  measureFirstUnread()
}

const scrollToEnd = () => thread.value?.scrollTo({ top: thread.value.scrollHeight })

// No scroll event comes when the thread or what it shows changes its size, e.g. while a reply makes
//   the message input taller or once an image has loaded.
const remeasure = () => {
  if (thread.value) knownSize = sizeOf(thread.value)

  if (isAtEnd.value) scrollToEnd()
  else onScroll()
}

useResizeObserver([thread, content], remeasure)

watch(
  () => [firstUnreadId.value, props.entries.length, props.isCustomerTyping, props.endingNote?.text],
  async () => {
    // A new entry sets itself up first, e.g. the sizes of its images.
    await nextTick()

    remeasure()
  },
  { flush: 'post' },
)

// The newest entry is the one that counts, from the history the window opens with on. An embedded
//   image in it has no size before the next tick.
onMounted(() => nextTick(scrollToEnd))

// The page comes back from outside the document, where the browser dropped the position.
onActivated(() => {
  const element = thread.value

  if (!element) return

  element.scrollTo({ top: isAtEnd.value ? element.scrollHeight : lastScrollTop })
})

// Typing, notices and the agent's own messages, also from another tab, are nothing to come back for.
const customerMessageCount = computed(
  () =>
    props.entries.filter((entry) => entry.kind === 'message' && !isAgentMessage(entry.message))
      .length,
)

watch(customerMessageCount, (count, previous) => {
  if (count > previous && !isAtEnd.value) hasNewBelow.value = true
})

// The count says that the button goes to the first unread message; the toolbar shows itself for a
//   count alone.
const unreadCount = computed(() =>
  hasNewBelow.value && isFirstUnreadAhead.value ? (props.unreadMessageIds?.size ?? 0) : 0,
)

const toolbar = useTemplateRef('toolbar')

// Gone with the focus, the button would leave a keyboard agent at the start of the page.
watch(isAtEnd, (isGone) => {
  if (isGone && toolbar.value?.$el?.contains?.(document.activeElement)) emit('leave')
})

const jumpToNew = () => {
  const offset = firstUnreadOffset()

  // Not `scrollIntoView`, which would move the row of windows as well.
  if (offset !== undefined) thread.value?.scrollTo({ top: thread.value.scrollTop + offset })
}
</script>

<template>
  <div class="relative flex min-h-0 grow flex-col">
    <div
      ref="thread"
      class="min-h-0 grow overflow-y-auto bg-blue-200 p-3 dark:bg-gray-700"
      role="log"
      @scroll.passive="onScroll"
    >
      <div ref="content" class="flex flex-col gap-6">
        <!-- Like the old interface: the page heads the history, as the first notice. -->
        <CommonLabel v-if="url" class="max-w-full self-center py-1" size="xs" role="note">
          <CommonTranslateRenderer
            v-if="isWebAddress(url)"
            v-tooltip.truncate.supportive="url"
            class="min-w-0 truncate"
            as="span"
            :source="__('Started from %s')"
            :placeholders="[{ type: 'link', props: { ...pageLinkProps, link: url }, content: url }]"
          />
          <span v-else v-tooltip.truncate.supportive="url" class="min-w-0 truncate">
            {{ $t('Started from %s', url) }}
          </span>
        </CommonLabel>

        <template v-for="{ entry, showTime, isFollowUp } in items" :key="entry.id">
          <div
            v-if="entry.id === firstUnreadId"
            ref="unread-divider"
            class="flex items-center gap-3"
          >
            <CommonDivider class="flex-1" variant="muted" aria-hidden="true" />
            <CommonLabel class="shrink-0 text-muted!" size="small" role="note">
              {{ $t('Unread messages') }}
            </CommonLabel>
            <CommonDivider class="flex-1" variant="muted" aria-hidden="true" />
          </div>

          <CommonLabel
            v-if="entry.kind === 'notice'"
            class="max-w-full self-center py-1 text-center"
            size="xs"
            role="note"
          >
            <CommonLink
              v-if="isWebAddress(entry.text)"
              v-tooltip.truncate.supportive="entry.text"
              v-bind="pageLinkProps"
              class="min-w-0 truncate"
              :link="entry.text"
            >
              {{ entry.text }}
            </CommonLink>
            <template v-else>{{ $t(entry.text) }}</template>
          </CommonLabel>

          <!-- Pulls a follow-up from the gap of 24px up to 8px below the message before. -->
          <ChatMessageBubble
            v-else
            :class="{ '-mt-4': isFollowUp }"
            :message="entry.message"
            :show-time="showTime"
          />
        </template>

        <ChatThreadEnding :note="endingNote" />

        <div
          v-if="isCustomerTyping"
          class="self-start rounded-2xl bg-blue-300 px-3 py-2 text-sm text-normal dark:bg-stone-700"
          :class="{ '-mt-4': isTypingFollowUp }"
          role="status"
          :aria-label="$t('The customer is typing')"
        >
          <!-- One line of text high, like a one-line message of the customer. -->
          <div class="flex h-lh items-center gap-1">
            <span
              v-for="dot in 3"
              :key="dot"
              class="size-1.5 animate-pulse rounded-full bg-current"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Outside the log, which would announce it like a message. -->
    <CommonFloatingToolbar
      ref="toolbar"
      class="absolute inset-x-1/2 bottom-3 ltr:-translate-x-1/2 rtl:translate-x-1/2"
      is-reaching-top
      :is-reaching-bottom="isAtEnd"
      :unread-count="unreadCount"
      @scroll-to-unread="jumpToNew"
      @scroll-to-end="scrollToEnd"
    />
  </div>
</template>
