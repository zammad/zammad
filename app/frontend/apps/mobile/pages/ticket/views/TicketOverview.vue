<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouteQuery } from '@vueuse/router'
import { storeToRefs } from 'pinia'
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import { useStickyHeader } from '#shared/composables/useStickyHeader.ts'
import { EnumOrderDirection } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonLoader from '#mobile/components/CommonLoader/CommonLoader.vue'
import CommonSelectPill from '#mobile/components/CommonSelectPill/CommonSelectPill.vue'
import CommonTicketCreateLink from '#mobile/components/CommonTicketCreateLink/CommonTicketCreateLink.vue'
import LayoutHeader from '#mobile/components/layout/LayoutHeader.vue'
import { useTicketOverviews } from '#mobile/entities/ticket/composables/useTicketOverviews.ts'

import TicketList from '../components/TicketList/TicketList.vue'
import TicketOrderBySelector from '../components/TicketList/TicketOrderBySelector.vue'

const application = useApplicationStore()

const props = defineProps<{
  overviewLink: string
}>()

const router = useRouter()
const route = useRoute()

const { overviews, loading: loadingOverviews } =
  storeToRefs(useTicketOverviews())

const optionsOverviews = computed(() => {
  return overviews.value.map((overview) => ({
    value: overview.link,
    label: `${i18n.t(overview.name)} (${overview.ticketCount})`,
  }))
})

const selectedOverview = computed(() => {
  return (
    overviews.value.find((overview) => overview.link === props.overviewLink) ||
    null
  )
})

const selectedOverviewLink = computed(() => {
  return selectedOverview.value?.link || null
})

const session = useSessionStore()

const hiddenColumns = computed(() => {
  if (session.hasPermission(['ticket.agent'])) return []
  const viewColumns =
    selectedOverview.value?.viewColumns.map((column) => column.key) || []
  // show priority only if it is specified in overview
  return ['priority', 'updated_by'].filter(
    (name) => !viewColumns.includes(name),
  )
})

const selectOverview = (link: string) => {
  const { query } = route
  return router.replace({ path: `/tickets/view/${link}`, query })
}

watch(
  [selectedOverview, overviews],
  async ([overview]) => {
    if (!overview && overviews.value.length) {
      const [firstOverview] = overviews.value
      await selectOverview(firstOverview.link)
    }
  },
  { immediate: true },
)

const userOrderBy = useRouteQuery<string | undefined>('column', undefined)

const orderColumnsOptions = computed(() => {
  return (
    selectedOverview.value?.orderColumns.map((entry) => {
      return { value: entry.key, label: entry.value || entry.key }
    }) || []
  )
})

const orderColumnLabels = computed(() => {
  return (
    selectedOverview.value?.orderColumns.reduce(
      (map, entry) => {
        map[entry.key] = entry.value || entry.key
        return map
      },
      {} as Record<string, string>,
    ) || {}
  )
})

// Check that the given order by column is really a valid column and otherwise
// reset query parameter.
watch(selectedOverview, () => {
  if (userOrderBy.value && !orderColumnLabels.value[userOrderBy.value]) {
    userOrderBy.value = undefined
  }
})

const orderBy = computed({
  get: () => {
    if (userOrderBy.value && orderColumnLabels.value[userOrderBy.value])
      return userOrderBy.value
    return selectedOverview.value?.orderBy
  },
  set: (column) => {
    userOrderBy.value =
      column !== selectedOverview.value?.orderBy ? column : undefined
  },
})

const columnLabel = computed(() => {
  return orderColumnLabels.value[orderBy.value || ''] || ''
})

const userOrderDirection = useRouteQuery<EnumOrderDirection | undefined>(
  'direction',
  undefined,
)

// Check that the given order direction is a valid direction, otherwise
// reset the query parameter.
if (
  userOrderDirection.value &&
  !Object.values(EnumOrderDirection).includes(userOrderDirection.value)
) {
  userOrderDirection.value = undefined
}

const orderDirection = computed({
  get: () => {
    if (userOrderDirection.value) return userOrderDirection.value
    return selectedOverview.value?.orderDirection
  },
  set: (direction) => {
    userOrderDirection.value =
      direction !== selectedOverview.value?.orderDirection
        ? direction
        : undefined
  },
})

const { stickyStyles, headerElement } = useStickyHeader([loadingOverviews])

const showRefetch = ref(false)
</script>

<template>
  <div>
    <header
      ref="headerElement"
      class="border-b-[0.5px] border-white/10 bg-black px-4"
      :style="stickyStyles.header"
    >
      <LayoutHeader
        back-url="/"
        container-tag="div"
        class="h-16 border-none first:px-0"
        back-avoid-home-button
        :refetch="showRefetch"
        :title="__('Tickets')"
      >
        <template #after>
          <CommonTicketCreateLink class="justify-self-end text-base" />
        </template>
      </LayoutHeader>
      <div
        v-if="optionsOverviews.length"
        class="mb-3 flex items-center justify-between gap-2"
        data-test-id="overview"
      >
        <CommonSelectPill
          :model-value="selectedOverviewLink"
          :options="optionsOverviews"
          no-options-label-translation
          @update:model-value="selectOverview($event as string)"
        >
          <span class="max-w-[55vw] truncate">
            {{ $t(selectedOverview?.name) }}
          </span>
          <span class="px-1"> ({{ selectedOverview?.ticketCount }}) </span>
        </CommonSelectPill>
        <TicketOrderBySelector
          v-model:order-by="orderBy"
          v-model:direction="orderDirection"
          :options="orderColumnsOptions"
          :label="columnLabel"
        />
      </div>
    </header>
    <div :style="stickyStyles.body">
      <CommonLoader
        v-if="loadingOverviews || overviews.length"
        :loading="loadingOverviews"
      >
        <TicketList
          v-if="selectedOverview && orderBy && orderDirection"
          :overview-id="selectedOverview.id"
          :overview-ticket-count="selectedOverview.ticketCount"
          :order-by="orderBy"
          :order-direction="orderDirection"
          :max-count="application.config.ui_ticket_overview_ticket_limit"
          :hidden-columns="hiddenColumns"
          @refetch="showRefetch = $event"
        />
      </CommonLoader>
      <div
        v-else
        class="flex items-center justify-center gap-2 p-4 text-center"
      >
        <CommonIcon class="text-red" name="close-small" />
        {{ $t('Currently no overview is assigned to your roles.') }}
      </div>
    </div>
  </div>
</template>
