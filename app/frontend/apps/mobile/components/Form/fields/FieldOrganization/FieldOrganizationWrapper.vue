<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { defineAsyncComponent, markRaw } from 'vue'

import { AutocompleteSearchOrganizationDocument } from '#shared/components/Form/fields/FieldOrganization/graphql/queries/autocompleteSearch/organization.api.ts'
import type { AutocompleteOrganizationProps } from '#shared/components/Form/fields/FieldOrganization/types.ts'
import { useFormFieldOrganizationInitialOptionBuilder } from '#shared/components/Form/fields/FieldOrganization/useFieldOrganizationInitialOptionBuilder.ts'

import FieldOrganizationOptionIcon from './FieldOrganizationOptionIcon.vue'

const FieldAutoCompleteInput = defineAsyncComponent(
  () =>
    import(
      '#mobile/components/Form/fields/FieldAutoComplete/FieldAutoCompleteInput.vue'
    ),
)

const props = defineProps<AutocompleteOrganizationProps>()

Object.assign(props.context, {
  optionIconComponent: markRaw(FieldOrganizationOptionIcon),
  initialOptionBuilder: useFormFieldOrganizationInitialOptionBuilder(),
  gqlQuery: AutocompleteSearchOrganizationDocument,
})
</script>

<template>
  <FieldAutoCompleteInput :context="context" v-bind="$attrs" />
</template>
