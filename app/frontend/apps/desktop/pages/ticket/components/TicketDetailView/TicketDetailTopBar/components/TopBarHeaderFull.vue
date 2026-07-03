<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonBreadcrumb from '#desktop/components/CommonBreadcrumb/CommonBreadcrumb.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonInlineEdit from '#desktop/components/CommonInlineEdit/CommonInlineEdit.vue'
import OrganizationPopoverWithTrigger from '#desktop/components/Organization/OrganizationPopoverWithTrigger.vue'
import UserPopoverWithTrigger from '#desktop/components/User/UserPopoverWithTrigger.vue'
import HighlightMenu from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/components/HighlightMenu.vue'
import TicketInformationBadgeList from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/components/TicketInformationFull/TicketInformationBadgeList.vue'

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

const items = computed(() => [
  {
    label: 'Tickets',
    to: { name: 'ticket-list' },
  },
  {
    label: ticketNumberWithTicketHook.value || '',
    noOptionLabelTranslation: true,
    to: { name: 'ticket-list' },
  },
])
</script>

<template>
  <header
    class="ticket-detail-grid-full grid grid-cols-2 gap-y-2.5 border-b border-neutral-100 bg-neutral-50 p-3 dark:border-gray-900 dark:bg-gray-500 print:border-b-0 print:px-3"
  >
    <CommonBreadcrumb
      emphasize-last-item
      size="small"
      :style="{ gridTemplate: 'breadcrumbs' }"
      :items="items"
      class="flex"
    >
      <template #trailing>
        <CommonButton
          v-if="ticketNumber"
          v-tooltip="$t('Copy ticket number')"
          variant="secondary"
          icon="files"
          size="small"
          class="ms-1 print:hidden"
          @click="copyTicketNumberToClipboard"
        />
      </template>
    </CommonBreadcrumb>

    <div
      v-if="isTicketAgent && isTicketEditable"
      class="justify-self-end print:hidden"
      :style="{ gridTemplate: 'actions' }"
    >
      <!-- Div because we add soon more actions here  -->
      <HighlightMenu />
    </div>

    <!-- 896px is the max width of the ArticleList -> max-w-64 and  64px is padding-->
    <!-- 12px padding for article bubble -->
    <!-- 896 - 64*2 - 12*2 = 744   -->
    <!-- 46.5rem for the middle grid to align with the content area -->
    <div
      v-if="ticket"
      :style="{ gridArea: 'info' }"
      class="grid grid-cols-[1fr_minmax(0,46.5rem)_1fr] gap-4"
    >
      <div
        class="flex w-full flex-col items-end gap-1.5 @5xl:mt-1 @5xl:flex-row @5xl:items-start @5xl:justify-end @5xl:gap-0"
      >
        <UserPopoverWithTrigger
          v-if="ticket.customer"
          class="z-11 h-min w-fit"
          :avatar-config="{
            responsive: true,
            size: 'normal',
          }"
          :popover-config="{
            placement: 'arrowStart',
          }"
          :user="ticket.customer"
        />
        <OrganizationPopoverWithTrigger
          v-if="ticket.organization"
          class="h-min w-fit @5xl:ltr:-translate-x-1.5 @5xl:rtl:translate-x-1.5"
          :avatar-config="{
            responsive: true,
            size: 'normal',
          }"
          :popover-config="{
            placement: 'arrowStart',
          }"
          :organization="ticket.organization"
        />
      </div>

      <div class="w-full grow justify-self-center">
        <div class="mb-3.5 flex flex-col justify-center">
          <div class="mb-1 flex items-center gap-1">
            <CommonLabel tag="p" class="line-clamp-1! max-w-1/2 shrink break-all">
              {{ ticket.customer.fullname }}
            </CommonLabel>
            <span v-if="ticket.organization?.name" aria-hidden="true"> &middot; </span>
            <CommonLabel
              v-if="ticket.organization?.name"
              class="line-clamp-1! flex-1 grow break-all"
            >
              {{ ticket.organization?.name }}
            </CommonLabel>
          </div>

          <CommonInlineEdit
            v-model:editing="isUpdatingTitle"
            size="xl"
            required
            block
            :disabled="!ticket.policy.update"
            :value="ticket.title"
            max-length="255"
            :classes="{
              label: 'dark:text-white font-medium',
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

        <TicketInformationBadgeList />
      </div>
    </div>
  </header>
</template>

<style scoped>
.ticket-detail-grid-full {
  grid-template-areas:
    'breadcrumbs actions'
    'info        info';
}
</style>
