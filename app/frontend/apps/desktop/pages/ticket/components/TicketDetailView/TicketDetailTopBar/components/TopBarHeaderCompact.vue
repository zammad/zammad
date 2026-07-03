<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonInlineEdit from '#desktop/components/CommonInlineEdit/CommonInlineEdit.vue'
import OrganizationPopoverWithTrigger from '#desktop/components/Organization/OrganizationPopoverWithTrigger.vue'
import UserPopoverWithTrigger from '#desktop/components/User/UserPopoverWithTrigger.vue'
import HighlightMenu from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/components/HighlightMenu.vue'

import { useTopBarHeader } from './useTopBarHeader.ts'

const {
  ticket,
  ticketNumber,
  ticketNumberWithTicketHook,
  isTicketAgent,
  isTicketEditable,
  copyTicketNumberToClipboard,
  isUpdatingTitle,
  updateTitle,
} = useTopBarHeader()
</script>

<template>
  <header
    class="grid grid-cols-[1fr_min-content] items-center border-b border-neutral-100 bg-neutral-50 p-3 @7xl:grid-cols-[1fr_minmax(0,56rem)_1fr] dark:border-gray-900 dark:bg-gray-500 print:hidden print:border-b-0"
  >
    <div class="col-start-1 row-start-1 flex items-center gap-1.5">
      <h1 class="line-clamp-1 text-xs break-all text-black dark:text-white">
        {{ ticketNumberWithTicketHook }}
      </h1>
      <CommonButton
        v-if="ticketNumber"
        v-tooltip="$t('Copy ticket number')"
        variant="secondary"
        icon="files"
        size="small"
        class="ms-1"
        @click="copyTicketNumberToClipboard"
      />
    </div>

    <!-- 896px is the max width of the ArticleList -> max-w-64 and  64px is padding-->
    <!-- 896 - 64*2 = 768  -->
    <!-- 48rem for the middle grid to align with the content area -->
    <div
      v-if="ticket"
      class="col-start-1 row-start-2 grid max-w-4xl grid-cols-[1fr_minmax(0,48rem)_1fr] items-center gap-3 justify-self-center @4xl:col-span-2 @7xl:col-start-2 @7xl:row-start-1 @7xl:max-w-none @7xl:justify-self-start"
    >
      <div class="flex justify-self-end ltr:-mr-3 @4xl:ltr:mr-0 rtl:-ml-3 @4xl:rtl:ml-0">
        <UserPopoverWithTrigger
          v-if="ticket.customer"
          class="z-11 h-min shrink-0"
          :avatar-config="{
            size: 'small',
          }"
          :popover-config="{
            placement: 'arrowStart',
          }"
          :user="ticket.customer"
        />
        <OrganizationPopoverWithTrigger
          v-if="ticket.organization"
          class="h-min shrink-0 ltr:-translate-x-5 @4xl:ltr:-translate-x-1.5 rtl:translate-x-5 @4xl:rtl:translate-x-1.5"
          :avatar-config="{
            size: 'small',
          }"
          :popover-config="{
            placement: 'arrowStart',
          }"
          :organization="ticket.organization"
        />
      </div>

      <!-- 48rem for the middle grid to align with the content area -->
      <!-- 1.5 rem some extra spacing => 46.5rem-->
      <div class="justify-start-center w-full max-w-186">
        <div class="flex flex-col justify-center">
          <CommonInlineEdit
            v-model:editing="isUpdatingTitle"
            size="xl"
            required
            block
            max-length="255"
            :value="ticket.title"
            :disabled="!ticket.policy.update"
            :classes="{
              label: 'dark:text-white font-medium line-clamp-1!',
              input: 'dark:text-white font-medium',
            }"
            :label-attrs="{
              role: 'heading',
              'aria-level': '2',
            }"
            :label="$t('Edit ticket title')"
            @submit-edit="updateTitle"
          />
        </div>
      </div>
    </div>

    <div
      v-if="isTicketAgent && isTicketEditable"
      class="col-start-2 justify-self-end @7xl:col-start-3 @7xl:row-start-1"
    >
      <!-- Div because we add soon more actions here  -->
      <HighlightMenu />
    </div>
  </header>
</template>
