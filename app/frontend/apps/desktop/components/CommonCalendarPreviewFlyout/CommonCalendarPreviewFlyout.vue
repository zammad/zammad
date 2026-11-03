<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useTemplateRef, watch } from 'vue'

import { getAttachmentLinks } from '#shared/composables/getAttachmentLinks.ts'
import { useHtmlLinks } from '#shared/composables/useHtmlLinks.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import openExternalLink from '#shared/utils/openExternalLink.ts'

import CommonDivider from '#desktop/components/CommonDivider/CommonDivider.vue'
import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { useCalendarIcsFileEventsQuery } from '#desktop/entities/calendar/ics-file/graphql/queries/events.api.ts'

import CommonCalendarPreviewFlyoutEvent from './CommonCalendarPreviewFlyoutEvent.vue'
import CommonCalendarPreviewFlyoutSkeleton from './CommonCalendarPreviewFlyoutSkeleton.vue'

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
const calendarEventsQueryLoading = calendarEventsQuery.loadingWithoutCachedResult()

const events = computed(() => calendarEventsQueryResult.value?.calendarIcsFileEvents ?? [])

const eventsElement = useTemplateRef('events-list')

const { setupLinksHandlers } = useHtmlLinks('/desktop')

// The linkified fields come in via `v-html`, so their anchors get the click handlers that open
//   them in a new tab attached here. Watching the element, not the events: the loader mounts the
//   list a frame after the result arrives, so the events alone would fire too early.
watch(eventsElement, (element) => {
  if (element) setupLinksHandlers(element)
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
    :header-title="__('Preview calendar')"
    :footer-action-options="{
      actionLabel: __('Download'),
      actionButton: { variant: 'primary' },
    }"
    name="common-calendar-preview"
    no-close-on-action
    @action="downloadCalendar"
  >
    <div class="@container">
      <CommonLoader :loading="calendarEventsQueryLoading">
        <template #skeleton>
          <CommonCalendarPreviewFlyoutSkeleton />
        </template>

        <!-- A file that cannot be parsed has no result, it only gets the error notification. -->
        <CommonAlert v-if="calendarEventsQueryResult && !events.length" variant="warning">
          {{ $t('No events can be shown because the calendar file does not contain any.') }}
        </CommonAlert>

        <div v-else ref="events-list" class="mb-4 flex flex-col gap-3">
          <template v-for="(event, index) in events" :key="index">
            <CommonDivider v-if="index > 0" />

            <CommonCalendarPreviewFlyoutEvent :event="event" />
          </template>
        </div>
      </CommonLoader>
    </div>
  </CommonFlyout>
</template>
