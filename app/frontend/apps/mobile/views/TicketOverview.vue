<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <!-- TODO: Only a first dummy implementation for testing -->
  <div>
    <h1>{{ i18n.t('Ticket Overview') }}</h1>
    <p v-on:click="goTo">Go to link Home</p>
    <p v-on:click="goBack">Go Back</p>

    <select v-model="selectedOverview" class="text-black">
      <option
        v-for="overview in overviews?.overviews.edges?.map(
          (edge) => edge?.node,
        )"
        v-bind:key="overview?.id"
        v-bind:value="overview?.id"
      >
        {{ overview?.name }} ({{ overview?.ticketCount }})
      </option>
    </select>
    <TicketList
      v-if="selectedOverview.length"
      v-bind:overview-id="selectedOverview"
    />
  </div>
</template>

<script setup lang="ts">
import { useOverviewsQuery } from '@common/graphql/api'
import useViewTransition from '@mobile/composables/useViewTransition'
import ViewTransitions from '@mobile/types/transition'
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import TicketList from '@mobile/components/ticket/TicketList.vue'
import { QueryHandler } from '@common/server/apollo/handler'

const router = useRouter()

const goTo = () => {
  const { setViewTransition } = useViewTransition()
  setViewTransition(ViewTransitions.REPLACE)

  router.replace('/')
}

const goBack = () => {
  const { setViewTransition } = useViewTransition()
  setViewTransition(ViewTransitions.PREV)

  router.go(-1)
}

const overviews = new QueryHandler(
  useOverviewsQuery({ withTicketCount: true }),
).result()

const selectedOverview = ref('')
</script>
