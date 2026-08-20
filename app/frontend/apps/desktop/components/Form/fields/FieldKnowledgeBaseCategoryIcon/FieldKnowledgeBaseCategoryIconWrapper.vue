<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, markRaw, reactive } from 'vue'

import type { AutocompleteSelectValue } from '#shared/components/Form/fields/FieldAutocomplete/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import { AutocompleteSearchKnowledgeBaseCategoryIconDocument } from '#desktop/entities/knowledge-base/graphql/queries/autocompleteSearchCategoryIcon.api.ts'
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'
import type { KnowledgeBaseIconSet } from '#desktop/entities/knowledge-base/types.ts'

import FieldAutoCompleteInput from '../FieldAutoComplete/FieldAutoCompleteInput.vue'

import FieldKnowledgeBaseCategoryIconOption from './FieldKnowledgeBaseCategoryIconOption.vue'
import FieldKnowledgeBaseCategoryIconSelected from './FieldKnowledgeBaseCategoryIconSelected.vue'

import type { AutoCompleteKnowledgeBaseCategoryIconOption } from './types.ts'
import type { AutoCompleteProps } from '../FieldAutoComplete/types.ts'

interface Props {
  context: FormFieldContext<
    AutoCompleteProps & {
      options?: AutoCompleteKnowledgeBaseCategoryIconOption[]
      // Catalog to pick from. Defaults to the icon set of the browsed knowledge
      // base, so a caller inside it does not have to pass one.
      iconSet?: KnowledgeBaseIconSet
    }
  >
}

const props = defineProps<Props>()

const knowledgeBaseStore = useKnowledgeBaseStore()

const iconSet = computed(() => props.context.iconSet ?? knowledgeBaseStore.iconSet)

// eslint-disable-next-line vue/no-mutating-props
Object.assign(props.context, {
  gqlQuery: AutocompleteSearchKnowledgeBaseCategoryIconDocument,
  // Read as a function so a switched icon set reaches the next search.
  additionalQueryParams: () => ({ iconSet: iconSet.value }),
  // The picker is meant to be browsed, not only searched, so opening it shows the
  // whole catalog — and keeps showing it after a pick, instead of collapsing to the
  // single chosen icon.
  defaultFilter: '*',
  alwaysApplyDefaultFilter: true,
  gridLayout: true,
  optionComponent: markRaw(FieldKnowledgeBaseCategoryIconOption),
  selectedOptionComponent: markRaw(FieldKnowledgeBaseCategoryIconSelected),
  // Icon names are catalog identifiers, not UI copy. Translating them would make the
  // displayed name diverge from the one the backend matches a query against.
  noOptionsLabelTranslation: true,
  // The picker never requires typing, so the initial empty state must not ask for it.
  emptyInitialLabelText: __('No results found'),
  // Only the codepoint is stored, so the option behind an already saved icon has to be
  // reconstructed from it — with the codepoint standing in for the name, which stays
  // unknown until the catalog is searched. Kept reactive, since the icon set may
  // resolve only after the knowledge base has loaded.
  initialOptionBuilder: (_: ObjectLike, value: AutocompleteSelectValue) =>
    reactive({
      value: value as string,
      label: String(value),
      iconSet,
    }),
})
</script>

<template>
  <FieldAutoCompleteInput :context="context" />
</template>
