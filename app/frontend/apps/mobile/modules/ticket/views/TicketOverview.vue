<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  useViewTransition,
  ViewTransitions,
} from '@mobile/components/transition/TransitionViewNavigation'
import { i18n } from '@shared/i18n'
import { OrderDirection, TicketOrderBy } from '@shared/graphql/types'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import { useTicketsOverviews } from '@mobile/modules/home/stores/ticketOverviews'
import CommonSelect from '@mobile/components/CommonSelect/CommonSelect.vue'
import { useRouteQuery } from '@vueuse/router'
import { storeToRefs } from 'pinia'
import TicketList from '../components/TicketList/TicketList.vue'

const props = defineProps<{
  overviewLink: string
}>()

const router = useRouter()
const route = useRoute()

const { setViewTransition } = useViewTransition()

const goBack = () => {
  setViewTransition(ViewTransitions.Prev)

  router.go(-1)
}

const { overviews, loading: loadingOverviews } = storeToRefs(
  useTicketsOverviews(),
)

const selectedOverview = computed(() => {
  return (
    overviews.value.find((overview) => overview.link === props.overviewLink) ||
    null
  )
})

const selectedOverviewLink = computed(() => {
  return selectedOverview.value?.link || null
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

// TODO when order on overview will be parsed, this should be taken from there by default
const orderColumn = useRouteQuery<TicketOrderBy>(
  'column',
  TicketOrderBy.CreatedAt,
)
const orderDirection = useRouteQuery<OrderDirection>(
  'direction',
  OrderDirection.Descending,
)

// TODO should be generated on server
const columns: Record<TicketOrderBy, string> = {
  [TicketOrderBy.CreatedAt]: __('Created at'),
  [TicketOrderBy.Title]: __('Title'),
  [TicketOrderBy.UpdatedAt]: __('Updated at'),
  [TicketOrderBy.Number]: __('Number'),
}

const columnOptions = Object.entries(columns).map(([value, label]) => ({
  value,
  label,
}))

const directionOptions = computed(() => [
  {
    value: OrderDirection.Descending,
    label: __('descending'),
    icon: 'long-arrow-down',
    iconProps: {
      size: 'tiny' as const,
      class: {
        'text-blue': orderDirection.value === OrderDirection.Descending,
      },
      fixedSize: { width: 12, height: 12 },
    },
  },
  {
    value: OrderDirection.Ascending,
    label: __('ascending'),
    icon: 'long-arrow-down',
    iconProps: {
      size: 'tiny' as const,
      class: [
        'rotate-180',
        {
          'text-blue': orderDirection.value === OrderDirection.Ascending,
        },
      ],
      fixedSize: { width: 12, height: 12 },
    },
  },
])

const optionsOverviews = computed(() => {
  return overviews.value.map((overview) => ({
    value: overview.link,
    label: `${i18n.t(overview.name)} (${overview.ticketCount})`,
  }))
})
</script>

<template>
  <div>
    <header class="border-b-[0.5px] border-white/10 px-4">
      <div class="grid h-16 grid-cols-3">
        <div
          class="flex cursor-pointer items-center justify-self-start text-base"
        >
          <div @click="goBack()">
            <CommonIcon name="arrow-left" size="small" />
          </div>
        </div>
        <div
          class="flex flex-1 items-center justify-center text-center text-lg font-bold"
        >
          {{ $t('Tickets') }}
        </div>
        <div
          class="flex cursor-pointer items-center justify-self-end text-base"
        >
          <CommonLink link="/#ticket/create">
            <CommonIcon name="plus" size="small" />
          </CommonLink>
        </div>
      </div>
      <div
        v-if="loadingOverviews || optionsOverviews.length"
        class="mb-3 flex items-center justify-between gap-2"
        data-test-id="overview"
      >
        <CommonLoader class="w-16" :loading="loadingOverviews">
          <FormKit
            type="select"
            size="small"
            :classes="{ wrapper: 'px-0' }"
            :model-value="selectedOverviewLink"
            :options="optionsOverviews"
            no-options-label-translation
            @update:model-value="selectOverview($event as string)"
          />
        </CommonLoader>
        <CommonSelect v-model="orderColumn" :options="columnOptions" no-close>
          <template #default="{ open }">
            <div
              class="flex cursor-pointer items-center gap-1 whitespace-nowrap text-blue"
              data-test-id="column"
              @click="open"
              @keydown.space="open"
            >
              <CommonIcon
                name="long-arrow-down"
                :class="{
                  'rotate-180': orderDirection === OrderDirection.Ascending,
                }"
                :fixed-size="{ width: 12, height: 12 }"
              />
              {{ orderColumn && $t(columns[orderColumn]) }}
            </div>
          </template>

          <template #footer>
            <div class="flex gap-2 p-3 text-white">
              <label
                v-for="option of directionOptions"
                :key="option.value"
                class="flex flex-1 cursor-pointer items-center justify-center rounded-md p-2"
                :class="{
                  'bg-gray-200 font-bold': option.value === orderDirection,
                }"
              >
                <input
                  v-model="orderDirection"
                  type="radio"
                  class="hidden"
                  :value="option.value"
                />
                <CommonIcon
                  v-if="option.icon"
                  :name="option.icon"
                  class="ltr:mr-1 rtl:ml-1"
                  v-bind="option.iconProps"
                />
                {{ option.label }}
              </label>
            </div>
          </template>
        </CommonSelect>
      </div>
    </header>
    <CommonLoader
      v-if="loadingOverviews || overviews.length"
      :loading="loadingOverviews"
    >
      <TicketList
        v-if="selectedOverview && orderColumn"
        :overview-id="selectedOverview.id"
        :order-by="orderColumn"
        :order-direction="orderDirection"
      />
    </CommonLoader>
    <div v-else class="flex items-center justify-center gap-2 p-4 text-center">
      <CommonIcon class="text-red" name="close-small" />
      {{
        $t(
          'Currently no overview is assigned to your roles. Please contact your administrator.',
        )
      }}
    </div>
  </div>
</template>
