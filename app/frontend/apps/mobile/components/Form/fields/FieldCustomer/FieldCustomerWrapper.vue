<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { markRaw, defineAsyncComponent } from 'vue'
import type { ObjectLike } from '#shared/types/utils.ts'
import { useUserCreate } from '#mobile/entities/user/composables/useUserCreate.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import type { AutoCompleteProps } from '#shared/components/Form/fields/FieldAutocomplete/types.ts'
import type { AutoCompleteCustomerOption } from '#shared/components/Form/fields/FieldCustomer/types.ts'
import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import { AutocompleteSearchUserDocument } from '#shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/user.api.ts'
import FieldCustomerOptionIcon from './FieldCustomerOptionIcon.vue'

const FieldAutoCompleteInput = defineAsyncComponent(
  () =>
    import(
      '#mobile/components/Form/fields/FieldAutoComplete/FieldAutoCompleteInput.vue'
    ),
)

interface Props {
  context: FormFieldContext<
    AutoCompleteProps & {
      options?: AutoCompleteCustomerOption[]
    }
  >
}

const props = defineProps<Props>()

const { openCreateUserDialog } = useUserCreate()

Object.assign(props.context, {
  optionIconComponent: markRaw(FieldCustomerOptionIcon),
  initialOptionBuilder: (
    initialEntityObject: ObjectLike,
    value: SelectValue,
    context: Props['context'],
  ) => {
    if (!context.belongsToObjectField || !initialEntityObject) return null

    const belongsToObject = initialEntityObject[context.belongsToObjectField]

    if (!belongsToObject) return null

    return {
      value,
      label: belongsToObject.fullname,
      // disabled: !object.active, // TODO: we can not use disabled for the active/inactive flag, because it will be no longer possible to select the option
      user: belongsToObject,
    }
  },

  actionIcon: 'mobile-new-customer',

  gqlQuery: AutocompleteSearchUserDocument,

  onActionClick: openCreateUserDialog,
})
</script>

<template>
  <FieldAutoCompleteInput :context="context" v-bind="$attrs" />
</template>
