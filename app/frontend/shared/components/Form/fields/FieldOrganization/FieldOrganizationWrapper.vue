<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { computed, defineAsyncComponent } from 'vue'
import type { ObjectLike } from '@shared/types/utils'
import type { FormFieldContext } from '@shared/components/Form/types/field'
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

const context = computed(() => ({
  ...props.context,
  optionIconComponent: FieldOrganizationOptionIcon,

  initialOptionBuilder: (
    initialEntityObject: ObjectLike,
    value: SelectValue,
    context: Props['context'],
  ) => {
    if (!context.belongsToObjectField) return null

    const belongsToObject = initialEntityObject[context.belongsToObjectField]

    if (!belongsToObject) return null

    return {
      value,
      label: belongsToObject.name,
      // disabled: !object.active, // TODO: we can not use disabled for the active/inactive flag, because it will be no longer possible to select the option
      organization: belongsToObject,
    }
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
}))
</script>

<template>
  <FieldAutoCompleteInput :context="context" v-bind="$attrs" />
</template>
