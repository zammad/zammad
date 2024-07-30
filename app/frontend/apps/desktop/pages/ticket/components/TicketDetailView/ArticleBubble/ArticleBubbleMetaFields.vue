<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'

import { useArticleMeta } from '#desktop/pages/ticket/components/TicketDetailView/ArticleMeta/useArticleMeta.ts'

interface Props {
  article: TicketArticle
}

const props = defineProps<Props>()

const { fields } = useArticleMeta(toRef(props, 'article'))
</script>

<template>
  <div
    class="grid grid-cols-[max-content_1fr] gap-x-3 gap-y-2 rounded-t-xl p-3"
  >
    <template v-for="(field, index) in fields" :key="`${field.label}-${index}`">
      <CommonLabel class="ltr:ml-auto rtl:mr-auto"
        >{{ $t(field.label) }}
      </CommonLabel>

      <div class="flex items-center gap-2">
        <Component
          :is="field.component || CommonLabel"
          :prefix-icon="field.icon && !field.component ? field.icon : undefined"
          v-bind="field.props || {}"
          :context="{ field, article }"
          class="text-black dark:text-white"
        >
          {{ field.value }}
        </Component>

        <template v-if="field.links?.length">
          <CommonLink
            v-for="{ url, api, label, target } of field.links"
            :key="url"
            :link="url"
            :rest-api="api"
            :target="target"
            class="text-sm text-white/75"
          >
            {{ $t(label) }}
          </CommonLink>
        </template>
      </div>
    </template>
  </div>
</template>
