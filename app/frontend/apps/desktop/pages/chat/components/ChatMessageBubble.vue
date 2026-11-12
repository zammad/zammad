<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, onMounted, ref, useTemplateRef } from 'vue'

import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'
import { useHtmlInlineImages } from '#shared/composables/useHtmlInlineImages.ts'
import { useHtmlLinks } from '#shared/composables/useHtmlLinks.ts'
import { useImageViewer, type ImageViewerFile } from '#shared/composables/useImageViewer.ts'
import { i18n } from '#shared/i18n.ts'

import { useChatAgentName } from '#desktop/entities/chat/composables/useChatAgentName.ts'
import type { ChatConversationMessage } from '#desktop/entities/chat/types.ts'
import { isAgentMessage } from '#desktop/entities/chat/utils.ts'

interface Props {
  message: ChatConversationMessage
  showTime?: boolean
}

const props = defineProps<Props>()

// The agent's own messages sit on the right, the customer's on the left.
const isOwn = computed(() => isAgentMessage(props.message))

const agentName = useChatAgentName(() => props.message.createdBy)

// The side tells a sighted agent who wrote it; a screen reader hears it. Not "you": after a transfer
//   the messages of the previous agent carry a creator too.
const sender = computed(() =>
  props.message.createdBy
    ? i18n.t('Message from %s', agentName.value)
    : i18n.t('Message from the customer'),
)

const contentElement = useTemplateRef('content')

const inlineImages = ref<ImageViewerFile[]>([])

const { showImage } = useImageViewer(inlineImages)

const { populateInlineImages } = useHtmlInlineImages(inlineImages, (index) =>
  showImage(inlineImages.value[index]),
)

// The widget sends an image as wide as the chat up to a maximum, which the shared image handling
//   replaces by the width: such an image keeps the size it came with.
const populateImagesKeepingRelativeSizes = (element: HTMLElement) => {
  const relativeSizes = [...element.querySelectorAll('img')]
    .filter((image) => image.style.width.endsWith('%'))
    .map((image) => ({ image, width: image.style.width, maxWidth: image.style.maxWidth }))

  populateInlineImages(element)

  relativeSizes.forEach(({ image, width, maxWidth }) => {
    image.style.width = width
    image.style.maxWidth = maxWidth
  })
}

// The image itself becomes the button, as an element around it would change how the message lays
//   it out.
const makeImagesOperableByKeyboard = (element: HTMLElement) =>
  element.querySelectorAll('img').forEach((image) => {
    image.tabIndex = 0
    image.setAttribute('role', 'button')
    image.setAttribute('aria-label', i18n.t('Open image preview'))
    image.classList.add('rounded-sm', 'focus-visible-app-default')

    image.onkeydown = (event) => {
      if (event.key !== 'Enter' && event.key !== ' ') return

      event.preventDefault()
      image.click()
    }
  })

const { setupLinksHandlers } = useHtmlLinks('/desktop')

// Every link gets a new window, so the chat stays open: the server leaves links to Zammad without one.
const setupLinks = (element: HTMLElement) => {
  element.querySelectorAll('a').forEach((link) => {
    link.target = '_blank'
  })

  setupLinksHandlers(element)
}

// The thread keys a bubble by its message, so its content never changes after mounting.
onMounted(() => {
  if (!contentElement.value) return

  populateImagesKeepingRelativeSizes(contentElement.value)
  makeImagesOperableByKeyboard(contentElement.value)
  setupLinks(contentElement.value)
})
</script>

<template>
  <div class="flex flex-col gap-2">
    <CommonDateTime
      v-if="showTime"
      class="px-4 text-xs text-muted"
      :class="isOwn ? 'self-end' : 'self-start'"
      :date-time="message.createdAt"
    />

    <div
      class="max-w-[85%] rounded-2xl px-3 py-2 text-sm wrap-break-word"
      :class="
        isOwn
          ? 'self-end bg-white text-normal dark:bg-gray-500 dark:text-white'
          : 'self-start bg-blue-300 text-normal dark:bg-stone-700'
      "
    >
      <span class="sr-only">{{ sender }}</span>

      <!-- The content is sanitized by the server, like the messages of the widget. -->
      <!-- eslint-disable vue/no-v-html -->
      <div ref="content" data-test-id="chat-message" v-html="message.content" />
      <!-- eslint-enable vue/no-v-html -->
    </div>
  </div>
</template>
