<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onActivated, useTemplateRef, watch } from 'vue'

import { useReducedMotion } from '#shared/composables/useReducedMotion.ts'

import { useTransitionConfig } from '#desktop/composables/useTransitionConfig.ts'

import ChatWindow from './ChatWindow.vue'

interface Props {
  sessionIds: string[]
}

const props = defineProps<Props>()

defineEmits<{
  close: [sessionId: string]
}>()

// The window to bring into view, cleared once it is.
const windowToReveal = defineModel<string>('windowToReveal')

const { transitions } = useTransitionConfig()

const { scrollBehavior } = useReducedMotion()

const windows = useTemplateRef('windows')

// A window growing into the row is narrower than it ends up, so the row cannot scroll to it before.
const enteringWindows = new WeakSet<Element>()

const findWindowToReveal = (): Element | undefined => {
  if (!windowToReveal.value) return undefined

  const chatWindow = windows.value?.find(
    (instance) => instance?.$props.sessionId === windowToReveal.value,
  )

  return chatWindow?.$el
}

// Nearest, so only a row that scrolls moves, and only as far as the window needs.
const reveal = (element: Element) => {
  if (!element.isConnected) return

  windowToReveal.value = undefined

  element.scrollIntoView({ behavior: scrollBehavior.value, block: 'nearest', inline: 'nearest' })
}

const revealRequested = () => {
  const element = findWindowToReveal()

  if (element && !enteringWindows.has(element)) reveal(element)
}

// The window can open before the request comes, or after it.
watch([windowToReveal, () => props.sessionIds], revealRequested, { deep: true, flush: 'post' })

onActivated(() => requestAnimationFrame(revealRequested))

const onBeforeEnter = (element: Element) => enteringWindows.add(element)

const onAfterEnter = (element: Element) => {
  enteringWindows.delete(element)

  if (element === findWindowToReveal()) reveal(element)
}
</script>

<template>
  <!-- The workspace of the old interface: each window a quarter of the row less its share of the
    three gaps, so four fit a row and a fifth wraps, with no width floor however narrow the sidebar
    leaves the row; the rows share the height and nothing scrolls. Below the small-screen
    breakpoint the row stops wrapping and snaps from window to window instead. -->
  <TransitionGroup
    tag="div"
    :name="transitions.chatWindow"
    class="flex flex-wrap gap-3 max-lg:snap-x max-lg:snap-mandatory max-lg:flex-nowrap max-lg:overflow-x-auto"
    @before-enter="onBeforeEnter"
    @after-enter="onAfterEnter"
  >
    <ChatWindow
      v-for="sessionId in sessionIds"
      ref="windows"
      :key="sessionId"
      class="grow basis-[calc(25%-9px)] max-lg:shrink-0 max-lg:basis-full max-lg:snap-center"
      :session-id="sessionId"
      @close="$emit('close', sessionId)"
    />
  </TransitionGroup>
</template>
