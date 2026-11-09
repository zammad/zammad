<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import EntityAttributeContent from '#shared/components/EntityAttributes/EntityAttribute.vue'
import { useEntityAttributes } from '#shared/entities/core/attributes/composables/useEntityAttributes.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

interface Props {
  context: {
    article: TicketArticle
  }
}

defineProps<Props>()

const { attributesLookup } = useEntityAttributes(EnumObjectManagerObjects.TicketArticle)

const detectedLanguageAttribute = computed(() => attributesLookup.value.get('detected_language'))
</script>

<template>
  <CommonLabel class="text-contrast!">
    <EntityAttributeContent
      v-if="detectedLanguageAttribute"
      :attribute="detectedLanguageAttribute"
      :object="context.article"
    />
    <template v-else>{{ context.article.detectedLanguage }}</template>
  </CommonLabel>
</template>
