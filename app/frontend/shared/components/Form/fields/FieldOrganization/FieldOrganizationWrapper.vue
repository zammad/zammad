<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { markRaw, defineAsyncComponent } from 'vue'
import type { ObjectLike } from '@shared/types/utils'
import type { FormFieldContext } from '@shared/components/Form/types/field'
import type { Organization } from '@shared/graphql/types'
import { getAutoCompleteOption } from '@shared/entities/organization/utils/getAutoCompleteOption'
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
    if (!context.belongsToObjectField) return null

    const belongsToObject = initialEntityObject[
      context.belongsToObjectField
    ] as Organization

    if (!belongsToObject) return null

    return getAutoCompleteOption(belongsToObject)
  },

  // TODO: change the action to the actual new organization route
  action: '/tickets',
  actionIcon: 'mobile-new-organization',

  // TODO: change the query to the actual autocomplete search of organizations
  gqlQuery: `
query autocompleteSearchOrganization($query: String!, $limit: Int) {
  autocompleteSearchOrganization(query: $query, limit: $limit) {
    value
    label
    labelPlaceholder
    heading
    headingPlaceholder
    disabled
    organization
  }
}
`,
})
</script>

<template>
  <FieldAutoCompleteInput :context="context" v-bind="$attrs" />
</template>
