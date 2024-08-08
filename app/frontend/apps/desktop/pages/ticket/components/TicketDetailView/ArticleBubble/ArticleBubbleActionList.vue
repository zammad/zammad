<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import openExternalLink from '#shared/utils/openExternalLink.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import { useEmailFileUrls } from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/useEmailFileUrls.ts'
import { useTicketArticleReply } from '#desktop/pages/ticket/composables/useTicketArticleReply.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

const props = defineProps<{
  position: 'left' | 'right'
  article: TicketArticle
}>()

const { canUpdateTicket } = useTicketArticleReply()
const { ticket } = useTicketInformation()

const { isTouchDevice } = useTouchDevice()

const buttonVariantClassExtension = computed(() => {
  if (props.position === 'left')
    return 'border border-neutral-100 !outline-transparent hover:border-blue-700 dark:hover:border-blue-700 hover:border-blue-800 bg-neutral-50 hover:bg-white text-gray-100 dark:border-gray-900 dark:bg-gray-500 dark:text-neutral-400'

  return 'border border-neutral-100 !outline-transparent hover:border-blue-700 dark:hover:border-blue-700 bg-blue-100 bg-blue-100  text-gray-100 dark:border-gray-900 dark:bg-stone-500 dark:text-neutral-400'
})

const popoverActions: MenuItem[] = [
  {
    key: 'article-permalink',
    label: __('Article permalink'),
    icon: 'link-45deg',
  },
  {
    key: 'download-original-email',
    label: __('Download original email'),
    onClick(arg) {
      const { article } = arg as { article: TicketArticle }
      const { originalFormattingUrl } = useEmailFileUrls(article)
      openExternalLink(originalFormattingUrl.value as string)
    },
    show: (arg) => {
      const { article } = arg as { article: TicketArticle }
      const { originalFormattingUrl } = useEmailFileUrls(article)
      return !!(article.type?.name === 'email' && originalFormattingUrl.value)
    },
    icon: 'download',
  },
  {
    key: 'download-raw-email',
    label: __('Download raw email'),
    onClick(arg) {
      const { article } = arg as { article: TicketArticle }
      const { rawMessageUrl } = useEmailFileUrls(article)
      openExternalLink(rawMessageUrl.value)
    },
    show: (arg) => {
      const { article } = arg as { article: TicketArticle }
      const { rawMessageUrl } = useEmailFileUrls(article)
      return !!(article.type?.name === 'email' && rawMessageUrl.value)
    },
    icon: 'download',
  },
  {
    key: 'forward',
    label: __('Forward'),
    icon: 'forward',
  },
  {
    key: 'remove',
    permission: ['ticket.agent'],
    label: __('Remove'),
    icon: 'trash3',
  },
  {
    key: 'reply',
    label: __('Reply'),
    icon: 'reply',
  },
  {
    key: 'external',
    label: __('Set to external'),
    icon: 'unlock',
  },
  {
    key: 'internal',
    label: __('Set to internal'),
    icon: 'lock',
  },
  {
    key: 'split',
    label: __('Split'),
    icon: 'split',
  },
]

const actions: MenuItem[] = [
  {
    key: 'reply',
    label: __('Reply'),
    icon: 'reply',
  },
]
</script>

<template>
  <div
    v-if="canUpdateTicket"
    class="group absolute bottom-0 flex w-fit translate-y-1/2 items-center gap-1 ltr:right-3 rtl:left-3"
    :class="{ 'ltr:left-3 rtl:right-3': position === 'left' }"
  >
    <div
      v-for="(action, index) in actions"
      :key="`${action.key}-${index}`"
      data-test-id="top-level-article-action-container"
      class="-:order-1 flex items-center"
      :class="{
        '-order-1': position === 'right',
        'opacity-0 transition-opacity group-hover:opacity-100': !isTouchDevice,
      }"
    >
      <CommonButton
        class="!py-0.5 px-1 !text-xs"
        :class="[buttonVariantClassExtension]"
        :prefix-icon="action.icon"
        >{{ $t(action.label) }}
      </CommonButton>
    </div>

    <CommonActionMenu
      class="flex"
      :no-padded-default-button="false"
      no-small-rounding-default-button
      :entity="{ ticket, article }"
      button-size="small"
      :placement="position === 'left' ? 'arrowStart' : 'arrowEnd'"
      :default-button-variant="
        position === 'left' ? 'neutral-dark' : 'neutral-light'
      "
      :actions="popoverActions"
    />
  </div>
</template>
