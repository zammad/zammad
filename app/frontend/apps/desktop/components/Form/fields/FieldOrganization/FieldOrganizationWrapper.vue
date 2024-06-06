<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { markRaw } from 'vue'

import useFormFieldOrganizationInitialOptionBuilder from '#shared/components/Form/fields/FieldOrganization/composables/useFieldOrganizationInitialOptionBuilder.ts'
import { AutocompleteSearchOrganizationDocument } from '#shared/components/Form/fields/FieldOrganization/graphql/queries/autocompleteSearch/organization.api.ts'
import type { AutocompleteOrganizationProps } from '#shared/components/Form/fields/FieldOrganization/types.ts'

import FieldAutoCompleteInput from '../FieldAutoComplete/FieldAutoCompleteInput.vue'

import FieldOrganizationOptionIcon from './FieldOrganizationOptionIcon.vue'

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
