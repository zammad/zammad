<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { markRaw, defineAsyncComponent } from 'vue'
import type { ObjectLike } from '@shared/types/utils'
import type { FormFieldContext } from '@shared/components/Form/types/field'
import type { Organization } from '@shared/graphql/types'
import { getAutoCompleteOption } from '@shared/entities/organization/utils/getAutoCompleteOption'
import { AutocompleteSearchOrganizationDocument } from '@shared/components/Form/fields/FieldOrganization/graphql/queries/autocompleteSearch/organization.api'
import FieldOrganizationOptionIcon from './FieldOrganizationOptionIcon.vue'
import type { AutoCompleteProps } from '../FieldAutoComplete/types'
import type { AutoCompleteOrganizationOption } from './types'
import type { SelectValue } from '../FieldSelect'

const FieldAutoCompleteInput = defineAsyncComponent(
  () =>
    import(
      '@shared/components/Form/fields/FieldAutoComplete/FieldAutoCompleteInput.vue'
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
