<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { i18n } from '@shared/i18n'
import CommonBackButton from '@mobile/components/CommonBackButton/CommonBackButton.vue'
import { EnumOrderDirection } from '@shared/graphql/types'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import { useTicketOverviewsStore } from '@mobile/entities/ticket/stores/ticketOverviews'
import CommonSelect from '@mobile/components/CommonSelect/CommonSelect.vue'
import { useApplicationStore } from '@shared/stores/application'
import { useSessionStore } from '@shared/stores/session'
import CommonSelectPill from '@mobile/components/CommonSelectPill/CommonSelectPill.vue'
import { useRouteQuery } from '@vueuse/router'
import { storeToRefs } from 'pinia'
import type { Sizes } from '@shared/components/CommonIcon/types'
import TicketList from '../components/TicketList/TicketList.vue'

const application = useApplicationStore()

const props = defineProps<{
  overviewLink: string
}>()

const router = useRouter()
const route = useRoute()

const { overviews, loading: loadingOverviews } = storeToRefs(
  useTicketOverviewsStore(),
)

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
    selectedOverview.value?.orderColumns.reduce((map, entry) => {
      map[entry.key] = entry.value || entry.key
      return map
    }, {} as Record<string, string>) || {}
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

const directionOptions = computed(() => [
  {
    value: EnumOrderDirection.Descending,
    label: __('descending'),
    icon: 'mobile-arrow-down',
    iconProps: {
      class: {
        'text-blue': orderDirection.value === EnumOrderDirection.Descending,
      },
      size: 'tiny' as Sizes,
    },
  },
  {
    value: EnumOrderDirection.Ascending,
    label: __('ascending'),
    icon: 'mobile-arrow-up',
    iconProps: {
      class: [
        {
          'text-blue': orderDirection.value === EnumOrderDirection.Ascending,
        },
      ],
      size: 'tiny' as Sizes,
    },
  },
])
</script>

<template>
  <div>
    <header class="border-b-[0.5px] border-white/10 px-4">
      <div class="grid h-16 grid-cols-3">
        <div
          class="flex cursor-pointer items-center justify-self-start text-base"
        >
          <CommonBackButton fallback="/" />
        </div>
        <h1
          class="flex flex-1 items-center justify-center text-center text-lg font-bold"
        >
          {{ $t('Tickets') }}
        </h1>
        <div
          class="flex cursor-pointer items-center justify-self-end text-base"
        >
          <CommonLink link="/#ticket/create">
            <CommonIcon name="mobile-add" size="small" />
          </CommonLink>
        </div>
      </div>
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
          <span
            class="max-w-[55vw] overflow-hidden text-ellipsis whitespace-nowrap"
          >
            {{ $t(selectedOverview?.name) }}
          </span>
          <span class="px-1"> ({{ selectedOverview?.ticketCount }}) </span>
        </CommonSelectPill>
        <CommonSelect v-model="orderBy" :options="orderColumnsOptions" no-close>
          <template #default="{ open }">
            <div
              class="flex cursor-pointer items-center gap-1 overflow-hidden whitespace-nowrap text-blue"
              data-test-id="column"
              @click="open"
              @keydown.space="open"
            >
              <div>
                <CommonIcon
                  :name="
                    orderDirection === EnumOrderDirection.Ascending
                      ? 'mobile-arrow-up'
                      : 'mobile-arrow-down'
                  "
                  size="tiny"
                />
              </div>
              <span class="overflow-hidden text-ellipsis whitespace-nowrap">
                {{ orderBy && $t(orderColumnLabels[orderBy]) }}
              </span>
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
      center
    >
      <TicketList
        v-if="selectedOverview && orderBy && orderDirection"
        :overview-id="selectedOverview.id"
        :order-by="orderBy"
        :order-direction="orderDirection"
        :max-count="Number(application.config.ui_ticket_overview_ticket_limit)"
        :hidden-columns="hiddenColumns"
      />
    </CommonLoader>
    <div v-else class="flex items-center justify-center gap-2 p-4 text-center">
      <CommonIcon class="text-red" name="mobile-close-small" />
      {{ $t('Currently no overview is assigned to your roles.') }}
    </div>
  </div>
</template>
