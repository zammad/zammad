<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, watch } from 'vue'

import { useTicketCreateArticleType } from '#shared/entities/ticket/composables/useTicketCreateArticleType.ts'
import { useTicketCreateView } from '#shared/entities/ticket/composables/useTicketCreateView.ts'
import type { TicketCreateArticleType } from '#shared/entities/ticket/types.ts'
import { type UserTaskbarItemEntityTicketCreate } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

import type { UserTaskbarTabEntityProps } from '../types.ts'

const props =
  defineProps<UserTaskbarTabEntityProps<UserTaskbarItemEntityTicketCreate>>()

const { ticketCreateArticleType, defaultTicketCreateArticleType } =
  useTicketCreateArticleType()

const { isTicketCustomer } = useTicketCreateView()

const ticketCreateLink = ref()

watch(
  () => ticketCreateLink.value?.isExactActive,
  (isExactActive) => {
    if (!isExactActive) return

    // Scroll the tab into view when it becomes active.
    ticketCreateLink.value?.$el?.scrollIntoView?.()
  },
)

const currentViewTitle = computed(() => {
  // Customer users should get a generic title prefix, since they cannot control the type of the first article.
  if (isTicketCustomer.value) {
    if (!props.context?.formValues?.title && !props.taskbarTab.entity?.title)
      return i18n.t('New Ticket')

    return i18n.t(
      'New Ticket: %s',
      (props.context?.formValues?.title as string) ||
        props.taskbarTab.entity?.title,
    )
  }

  if (
    !props.context?.formValues?.articleSenderType &&
    !props.taskbarTab.entity?.createArticleTypeKey
  )
    return i18n.t(
      ticketCreateArticleType[defaultTicketCreateArticleType]?.label,
    )

  const createArticleTypeKey = (props.context?.formValues?.articleSenderType ||
    props.taskbarTab.entity?.createArticleTypeKey) as TicketCreateArticleType

  if (!props.context?.formValues?.title && !props.taskbarTab.entity?.title)
    return i18n.t(ticketCreateArticleType[createArticleTypeKey]?.label)

  return i18n.t(
    ticketCreateArticleType[createArticleTypeKey]?.title,
    (props.context?.formValues?.title as string) ||
      props.taskbarTab.entity?.title,
  )
})
</script>

<template>
  <CommonLink
    v-if="taskbarTabLink"
    ref="ticketCreateLink"
    v-tooltip="currentViewTitle"
    class="flex grow gap-2 rounded-md px-2 py-3 hover:no-underline focus-visible:rounded-md focus-visible:outline-none group-hover/tab:bg-blue-600 group-hover/tab:dark:bg-blue-900"
    :link="taskbarTabLink"
    exact-active-class="!bg-blue-800 text-white"
    internal
  >
    <CommonIcon
      class="-:text-stone-200 -:dark:text-neutral-500 shrink-0 group-focus-visible/link:text-white"
      name="pencil"
      size="small"
      decorative
    />

    <CommonLabel
      class="-:text-gray-300 -:dark:text-neutral-400 block truncate group-hover/tab:text-white group-focus-visible/link:text-white"
    >
      {{ currentViewTitle }}
    </CommonLabel>
  </CommonLink>
</template>

<style scoped>
.router-link-active {
  @apply text-white;

  .icon,
  span {
    @apply text-white;
  }
}
</style>
