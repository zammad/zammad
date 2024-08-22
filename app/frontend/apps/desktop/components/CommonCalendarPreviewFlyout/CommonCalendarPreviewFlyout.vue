<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { getAttachmentLinks } from '#shared/composables/getAttachmentLinks.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import getUuid from '#shared/utils/getUuid.ts'
import openExternalLink from '#shared/utils/openExternalLink.ts'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonSimpleTable from '#desktop/components/CommonSimpleTable/CommonSimpleTable.vue'
import type { TableHeader } from '#desktop/components/CommonSimpleTable/types.ts'
import { useCalendarIcsFileEventsQuery } from '#desktop/entities/calendar/ics-file/graphql/queries/events.api.ts'

interface Props {
  fileId: string
  fileType: string
  fileName: string
}

const props = defineProps<Props>()

const calendarEventsQuery = new QueryHandler(
  useCalendarIcsFileEventsQuery({
    fileId: props.fileId,
  }),
)
const calendarEventsQueryResult = calendarEventsQuery.result()
const calendarEventsQueryLoading = calendarEventsQuery.loading()

const tableHeaders: TableHeader[] = [
  {
    key: 'summary',
    label: __('Event Summary'),
  },
  {
    key: 'location',
    label: __('Event Location'),
  },
  {
    key: 'start',
    label: __('Event Starting'),
    type: 'timestamp_absolute',
  },
  {
    key: 'end',
    label: __('Event Ending'),
    type: 'timestamp_absolute',
  },
]

const tableItems = computed(() => {
  if (!calendarEventsQueryResult.value?.calendarIcsFileEvents) return []

  return calendarEventsQueryResult.value?.calendarIcsFileEvents.map(
    (event) => ({
      id: getUuid(),
      summary: event.title,
      location: event.location,
      start: event.startDate,
      end: event.endDate,
    }),
  )
})

const downloadCalendar = () => {
  const application = useApplicationStore()

  const { downloadUrl } = getAttachmentLinks(
    {
      internalId: getIdFromGraphQLId(props.fileId),
      type: props.fileType,
    },
    application.config.api_path,
  )

  openExternalLink(downloadUrl, '_blank', props.fileName)
}
</script>

<template>
  <CommonFlyout
    :header-title="__('Preview Calendar')"
    :footer-action-options="{
      actionLabel: __('Download'),
      actionButton: { variant: 'primary' },
    }"
    name="common-calendar-preview"
    no-close-on-action
    @action="downloadCalendar"
  >
    <CommonLoader :loading="calendarEventsQueryLoading">
      <CommonSimpleTable
        class="mb-4 w-full"
        :headers="tableHeaders"
        :items="tableItems"
      />
    </CommonLoader>
  </CommonFlyout>
</template>
