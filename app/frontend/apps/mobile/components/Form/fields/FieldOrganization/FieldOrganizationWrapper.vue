<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { markRaw, defineAsyncComponent } from 'vue'
import type { ObjectLike } from '#shared/types/utils.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import type { Organization } from '#shared/graphql/types.ts'
import { getAutoCompleteOption } from '#shared/entities/organization/utils/getAutoCompleteOption.ts'
import type { AutoCompleteProps } from '#shared/components/Form/fields/FieldAutocomplete/types.ts'
import type { AutoCompleteOrganizationOption } from '#shared/components/Form/fields/FieldOrganization/types.ts'
import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import { AutocompleteSearchOrganizationDocument } from '#shared/components/Form/fields/FieldOrganization/graphql/queries/autocompleteSearch/organization.api.ts'
import FieldOrganizationOptionIcon from './FieldOrganizationOptionIcon.vue'

const FieldAutoCompleteInput = defineAsyncComponent(
  () =>
    import(
      '#mobile/components/Form/fields/FieldAutoComplete/FieldAutoCompleteInput.vue'
    ),
)

interface Props {
  context: FormFieldContext<
    AutoCompleteProps & {
      options?: AutoCompleteOrganizationOption[]
    }
  >
}

const props = defineProps<Props>()

Object.assign(props.context, {
  optionIconComponent: markRaw(FieldOrganizationOptionIcon),
  initialOptionBuilder: (
    initialEntityObject: ObjectLike,
    value: SelectValue,
    context: Props['context'],
  ) => {
    if (!context.belongsToObjectField || !initialEntityObject) return null

    const belongsToObject = initialEntityObject[
      context.belongsToObjectField
    ] as Organization

    if (!belongsToObject) return null

    return getAutoCompleteOption(belongsToObject)
  },
  gqlQuery: AutocompleteSearchOrganizationDocument,
})
</script>

<template>
  <FieldAutoCompleteInput :context="context" v-bind="$attrs" />
</template>
