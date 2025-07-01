<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useSessionStore } from '#shared/stores/session.ts'
import { useRouter } from 'vue-router'
import { useTicketCreateView } from '#shared/entities/ticket/composables/useTicketCreateView.ts'

import LayoutMain from '#desktop/components/layout/LayoutMain.vue'
import CommonContentPanel from '#desktop/components/CommonContentPanel/CommonContentPanel.vue'
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import TodaysTicketsWidget from '../components/TodaysTicketsWidget.vue'

const session = useSessionStore()
const router = useRouter()
const { ticketCreateEnabled } = useTicketCreateView()

const handleNewTicket = () => {
  if (ticketCreateEnabled.value) {
    router.push('/tickets/create')
  }
}

const handleAllTickets = () => {
  router.push('/tickets/view/my_assigned')
}

</script>

<template>
  <LayoutMain>
    <div class="p-6 space-y-6">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-black dark:text-white mb-2">
          {{ $t('Welcome back, %s!', session.user?.fullname) }}
        </h1>
        <p class="text-black dark:text-white">
          {{ $t("Here's what's happening with your tickets today.") }}
        </p>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
        <div class="col-span-1 lg:col-span-2">
          <TodaysTicketsWidget />
        </div>

        <CommonContentPanel>
          <div class="space-y-4">
            <CommonLabel size="large" class="text-gray-100 dark:text-neutral-400">
              {{ $t('Quick Actions') }}
            </CommonLabel>

            <div class="space-y-3">
              <CommonButton v-if="ticketCreateEnabled" @click="handleNewTicket" variant="secondary" size="large"
                class="w-full justify-start p-4 bg-blue-50 hover:bg-blue-100 dark:bg-blue-900/20 dark:hover:bg-blue-900/30"
                :aria-label="$t('Create a new support ticket')">
                <div class="flex items-start w-full">
                  <svg class="w-5 h-5 text-blue-500 mr-3 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor"
                    viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                  </svg>
                  <div class="flex-1">
                    <CommonLabel class="font-medium text-blue-900 dark:text-blue-100">
                      {{ $t('Create New Ticket') }}
                    </CommonLabel>

                  </div>
                </div>
              </CommonButton>

              <CommonButton @click="handleAllTickets" variant="secondary" size="large"
                class="w-full justify-start p-4 bg-green-50 hover:bg-green-100 dark:bg-green-900/20 dark:hover:bg-green-900/30"
                :aria-label="$t('View all your assigned tickets')">
                <div class="flex items-start w-full">
                  <svg class="w-5 h-5 text-green-500 mr-3 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor"
                    viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                      d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                  </svg>
                  <div class="flex-1">
                    <CommonLabel class="font-medium text-green-900 dark:text-green-100">
                      {{ $t('All Tickets') }}
                    </CommonLabel>

                  </div>
                </div>
              </CommonButton>
            </div>
          </div>
        </CommonContentPanel>
      </div>
    </div>
  </LayoutMain>
</template>