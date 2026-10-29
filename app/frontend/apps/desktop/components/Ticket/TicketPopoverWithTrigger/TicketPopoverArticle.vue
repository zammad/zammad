<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { EnumTicketArticleSenderName } from '#shared/graphql/types.ts'
import type { TicketPopoverArticleFragment } from '#shared/graphql/types.ts'

import { useBubbleStyleGuide } from '#desktop/composables/useBubbleStyleGuide.ts'

interface Props {
  label: string
  article: TicketPopoverArticleFragment
}

const props = defineProps<Props>()

// Same side as in the ticket detail view, where the side alone tells a colleague from the customer.
const position = computed(() =>
  props.article.sender?.name === EnumTicketArticleSenderName.Customer ? 'right' : 'left',
)

const isInternal = computed(() => props.article.internal)

const { articleBodyClasses, frameBorderClass, articleWrapperBorderClass, internalNoteClass } =
  useBubbleStyleGuide(position, isInternal)
</script>

<template>
  <div>
    <CommonLabel size="small" class="block! text-muted!" tag="p">
      {{ $t(label) }}
    </CommonLabel>

    <div
      class="flex items-end gap-2.5"
      :class="[
        // The striped frame of an internal note bleeds past the bubble and would touch the label.
        isInternal ? 'mt-2.5' : 'mt-1',
        { 'flex-row-reverse': position === 'right' },
      ]"
      data-test-id="popover-article-bubble"
    >
      <CommonUserAvatar :entity="article.author" size="small" decorative />

      <div
        class="min-w-0 flex-1 rounded-xl"
        :class="[frameBorderClass, internalNoteClass, articleWrapperBorderClass]"
      >
        <div class="space-y-1.5 rounded-[inherit] p-3" :class="articleBodyClasses">
          <div class="flex gap-1.5">
            <CommonLabel size="small" class="line-clamp-1! min-w-0 flex-1 font-bold">
              {{ article.author.fullname }}
            </CommonLabel>
            <CommonLabel size="small" class="shrink-0 text-muted!">
              <CommonDateTime :date-time="article.createdAt" type="relative" />
            </CommonLabel>
          </div>

          <CommonLabel class="block! wrap-anywhere" tag="p">
            {{ article.bodyExcerpt }}
          </CommonLabel>
        </div>
      </div>
    </div>
  </div>
</template>
