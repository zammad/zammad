<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useOverviewsQuery } from '@shared/entities/ticket/graphql/queries/overviews.api'
import {
  useViewTransition,
  ViewTransitions,
} from '@mobile/components/transition/TransitionViewNavigation'
import { QueryHandler } from '@shared/server/apollo/handler'
import TicketList from '../components/TicketList/TicketList.vue'

const router = useRouter()

const goTo = () => {
  const { setViewTransition } = useViewTransition()
  setViewTransition(ViewTransitions.Replace)

  router.replace('/')
}

const goBack = () => {
  const { setViewTransition } = useViewTransition()
  setViewTransition(ViewTransitions.Prev)

  router.go(-1)
}

const overviews = new QueryHandler(
  useOverviewsQuery({ withTicketCount: true }),
).result()

const selectedOverview = ref('')
</script>

<template>
  <!-- TODO: Only a first dummy implementation for testing -->
  <div>
    <h1>{{ i18n.t('Ticket Overview') }}</h1>
    <p @click="goTo">Go to link Home</p>
    <p @click="goBack">Go Back</p>

    <select v-model="selectedOverview" class="text-black">
      <option
        v-for="overview in overviews?.overviews.edges?.map(
          (edge) => edge?.node,
        )"
        :key="overview?.id"
        :value="overview?.id"
      >
        {{ overview?.name }} ({{ overview?.ticketCount }})
      </option>
    </select>
    <TicketList
      v-if="selectedOverview.length"
      :overview-id="selectedOverview"
    />
  </div>
</template>
