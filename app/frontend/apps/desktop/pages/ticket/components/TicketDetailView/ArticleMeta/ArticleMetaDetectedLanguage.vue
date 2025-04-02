<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import ObjectAttributeContent from '#shared/components/ObjectAttributes/ObjectAttribute.vue'
import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

interface Props {
  context: {
    article: TicketArticle
  }
}

defineProps<Props>()

const { attributesLookup } = useObjectAttributes(
  EnumObjectManagerObjects.TicketArticle,
)

const detectedLanguageAttribute = computed(() =>
  attributesLookup.value.get('detected_language'),
)
</script>

<template>
  <CommonLabel class="text-black! dark:text-white!">
    <ObjectAttributeContent
      v-if="detectedLanguageAttribute"
      :attribute="detectedLanguageAttribute"
      :object="context.article"
    />
    <template v-else>{{ context.article.detectedLanguage }}</template>
  </CommonLabel>
</template>
