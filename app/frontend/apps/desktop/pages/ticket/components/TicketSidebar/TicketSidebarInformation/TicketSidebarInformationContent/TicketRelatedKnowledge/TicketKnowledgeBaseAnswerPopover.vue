<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import CommonLink from '#shared/components/CommonLink/CommonLink.vue'
import type { KnowledgeBaseAnswerTranslationFragment } from '#shared/graphql/types.ts'

import CommonObjectAttribute from '#desktop/components/CommonObjectAttribute/CommonObjectAttribute.vue'
import CommonObjectAttributeContainer from '#desktop/components/CommonObjectAttribute/CommonObjectAttributeContainer.vue'
import KnowledgeBaseAnswerIcon from '#desktop/components/KnowledgeBaseAnswerIcon/KnowledgeBaseAnswerIcon.vue'
import { knowledgeBaseBrowseRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

interface Props {
  translation: KnowledgeBaseAnswerTranslationFragment
}

const props = defineProps<Props>()

const answer = computed(() => props.translation.answer)
const category = computed(() => answer.value.category)
const systemLocale = computed(() => props.translation.kbLocale.systemLocale)

const categoryRoute = computed(() =>
  knowledgeBaseBrowseRoute(systemLocale.value.locale, category.value.id),
)
</script>

<template>
  <section data-type="popover" class="space-y-3 p-3">
    <div class="flex items-center gap-1.25">
      <KnowledgeBaseAnswerIcon show-tooltip :visibility="translation.visibility" size="tiny" />
      <CommonLabel v-tooltip.supportive="translation.title" class="line-clamp-1! grow">
        {{ translation.title }}
      </CommonLabel>
    </div>

    <CommonLabel
      v-if="translation.content.bodyExcerpt"
      class="text-stone-200! dark:text-neutral-500!"
    >
      {{ translation.content.bodyExcerpt }}
    </CommonLabel>

    <CommonObjectAttributeContainer class="*:col-span-1">
      <CommonObjectAttribute v-if="answer.publishedAt" :label="__('Published at')">
        <CommonDateTime :date-time="answer.publishedAt" type="relative" />
      </CommonObjectAttribute>

      <CommonObjectAttribute v-if="answer.archivedAt" :label="__('Archived at')">
        <CommonDateTime :date-time="answer.archivedAt" type="relative" />
      </CommonObjectAttribute>

      <CommonObjectAttribute v-if="category.title" :label="__('Category')">
        <CommonLink :link="categoryRoute" size="medium" class="line-clamp-1">
          {{ category.title }}
        </CommonLink>
      </CommonObjectAttribute>

      <CommonObjectAttribute :label="__('Language')">
        <CommonLabel class="dark:text-neutral-500!">
          {{ systemLocale.name }}
        </CommonLabel>
      </CommonObjectAttribute>
    </CommonObjectAttributeContainer>
  </section>
</template>
