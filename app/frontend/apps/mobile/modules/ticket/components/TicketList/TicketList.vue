<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'
import { OrderDirection, TicketOrderBy } from '@shared/graphql/types'
import { QueryHandler } from '@shared/server/apollo/handler'
import usePagination from '@mobile/composables/usePagination'
import { useTicketsByOverviewQuery } from '../../graphql/queries/ticketsByOverview.api'

interface Props {
  overviewId: string
}

const props = defineProps<Props>()

const orderBy = ref(TicketOrderBy.Title)
const orderDirection = ref(OrderDirection.Ascending)

const switchOrder = (newOrderBy: TicketOrderBy) => {
  if (orderBy.value === newOrderBy) {
    orderDirection.value =
      orderDirection.value === OrderDirection.Ascending
        ? OrderDirection.Descending
        : OrderDirection.Ascending
    return
  }
  orderBy.value = newOrderBy
  orderDirection.value = OrderDirection.Ascending
}

const ticketsQuery = new QueryHandler(
  useTicketsByOverviewQuery(() => {
    return {
      overviewId: props.overviewId,
      orderBy: orderBy.value,
      orderDirection: orderDirection.value,
    }
  }),
)

const tickets = ticketsQuery.result()

const pagination = usePagination(ticketsQuery, 'ticketsByOverview')
</script>

<template>
  <!-- TODO: Only a first dumy implementation for a list -->
  <table>
    <thead>
      <th @click="switchOrder(TicketOrderBy.Title)">
        {{ i18n.t('Title') }}
        <span v-if="orderBy == TicketOrderBy.Title">
          <span v-if="orderDirection == OrderDirection.Ascending">⇑</span>
          <span v-else>⇓</span>
        </span>
      </th>
      <th>{{ i18n.t('Status') }}</th>
      <th @click="switchOrder(TicketOrderBy.Number)">
        {{ i18n.t('Number') }}
        <span v-if="orderBy == TicketOrderBy.Number">
          <span v-if="orderDirection == OrderDirection.Ascending">⇑</span>
          <span v-else>⇓</span>
        </span>
      </th>
      <th>{{ i18n.t('Customer') }}</th>
      <th>{{ i18n.t('Created') }}</th>
    </thead>
    <tbody>
      <tr
        v-for="ticket in tickets?.ticketsByOverview?.edges?.map(
          (edge) => edge?.node,
        )"
        :key="ticket?.number"
      >
        <td>{{ ticket?.title }}</td>
        <td>{{ ticket?.state.name }}</td>
        <td>{{ ticket?.number }}</td>
        <td>
          {{ ticket?.customer.firstname }} {{ ticket?.customer.lastname }}
        </td>
        <td>
          <CommonDateTime :date-time="ticket?.createdAt" />
        </td>
      </tr>
    </tbody>
  </table>
  <p v-if="pagination.hasNextPage">
    <a @click="pagination.fetchNextPage()">Load more...</a>
  </p>
</template>
