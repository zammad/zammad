<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import CommonLink from '#shared/components/CommonLink/CommonLink.vue'
import {
  EnumKnowledgeBaseVisibility,
  type KnowledgeBaseAnswerTranslationFragment,
} from '#shared/graphql/types.ts'

import CommonObjectAttribute from '#desktop/components/CommonObjectAttribute/CommonObjectAttribute.vue'
import CommonObjectAttributeContainer from '#desktop/components/CommonObjectAttribute/CommonObjectAttributeContainer.vue'
import { visibilityMeta } from '#desktop/components/KnowledgeBaseAnswerIcon/visibilityMeta.ts'
import { useKnowledgeBaseAnswerReachedDates } from '#desktop/entities/knowledge-base/composables/useKnowledgeBaseAnswerReachedDates.ts'
import { knowledgeBaseBrowseRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'
import { tagSearchRoute } from '#desktop/entities/tags/utils/routeLocation.ts'

interface Props {
  translation: KnowledgeBaseAnswerTranslationFragment
}

const props = defineProps<Props>()

const answer = computed(() => props.translation.answer)

// The three publication columns carry the answer's history and its scheduled changes at once, so
//   the rows below read the clock-filtered dates rather than the fields as they arrived: an
//   archival scheduled for next week is not something this panel may date as "Archived".
const { reachedDates } = useKnowledgeBaseAnswerReachedDates(answer)

const category = computed(() => answer.value.category)
const systemLocale = computed(() => props.translation.kbLocale.systemLocale)
const tags = computed(() => answer.value.tags ?? [])

const categoryRoute = computed(() =>
  knowledgeBaseBrowseRoute(systemLocale.value.locale, category.value.id),
)

// The link only shows the direct category, so the full path goes into a tooltip. Skipped for
//   top-level categories, where it would just repeat the visible title.
const categoryPath = computed(() => {
  const tree = props.translation.categoryTreeTranslation

  if (tree.length < 2) return undefined

  return tree.map((categoryTranslation) => categoryTranslation.title).join(' › ')
})
</script>

<template>
  <CommonObjectAttributeContainer
    class="grid-cols-1! *:col-span-1 @lg:grid-cols-2! @3xl:grid-cols-3!"
  >
    <CommonObjectAttribute
      v-if="reachedDates.internalAt"
      :label="visibilityMeta[EnumKnowledgeBaseVisibility.Internal].timestampLabel"
    >
      <CommonDateTime :date-time="reachedDates.internalAt" type="relative" />
    </CommonObjectAttribute>

    <CommonObjectAttribute
      v-if="reachedDates.publishedAt"
      :label="visibilityMeta[EnumKnowledgeBaseVisibility.Published].timestampLabel"
    >
      <CommonDateTime :date-time="reachedDates.publishedAt" type="relative" />
    </CommonObjectAttribute>

    <CommonObjectAttribute
      v-if="reachedDates.archivedAt"
      :label="visibilityMeta[EnumKnowledgeBaseVisibility.Archived].timestampLabel"
    >
      <CommonDateTime :date-time="reachedDates.archivedAt" type="relative" />
    </CommonObjectAttribute>

    <CommonObjectAttribute v-if="category.title" :label="__('Category')">
      <CommonLink
        v-tooltip.supportive="categoryPath"
        :link="categoryRoute"
        size="medium"
        open-in-new-tab
        class="line-clamp-1"
      >
        {{ category.title }}
      </CommonLink>
    </CommonObjectAttribute>

    <CommonObjectAttribute :label="__('Language')">
      <CommonLabel>
        {{ systemLocale.name }}
      </CommonLabel>
    </CommonObjectAttribute>

    <CommonObjectAttribute v-if="tags.length" :label="__('Tags')">
      <ul class="flex flex-wrap gap-1.5">
        <li
          v-for="tag in tags"
          :key="tag"
          class="flex rounded-md bg-blue-200 px-1.5 py-0.5 dark:bg-gray-700"
        >
          <CommonLabel size="small" prefix-icon="tag">
            <CommonLink class="line-clamp-1!" size="small" :link="tagSearchRoute(tag)">
              {{ tag }}
            </CommonLink>
          </CommonLabel>
        </li>
      </ul>
    </CommonObjectAttribute>
  </CommonObjectAttributeContainer>
</template>
