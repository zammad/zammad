<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonIcon from '#shared/components/CommonIcon/CommonIcon.vue'
import { useEmailFileUrls } from '#shared/composables/useEmailFileUrls.ts'
import type { TicketArticle } from '#shared/entities/ticket/types'

import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

interface Props {
  article: TicketArticle
}

const props = defineProps<Props>()

const { ticketInternalId } = useTicketInformation()

const { originalFormattingUrl } = useEmailFileUrls(
  props.article,
  ticketInternalId,
)
</script>

<template>
  <div
    v-if="article.preferences?.remote_content_removed"
    class="flex flex-row gap-1 p-3"
    role="alert"
  >
    <CommonIcon class="shrink-0" name="exclamation-triangle" size="small" />
    <CommonLabel class="block">
      {{
        i18n.t(
          'This message contains images or other content hosted by an external source. It was blocked, but you can download the original formatting.',
        )
      }}
      <br />
      <CommonLink
        v-if="originalFormattingUrl"
        :link="originalFormattingUrl"
        size="medium"
        target="_blank"
      >
        {{ i18n.t('Original Formatting') }}
      </CommonLink>
    </CommonLabel>
  </div>
</template>
