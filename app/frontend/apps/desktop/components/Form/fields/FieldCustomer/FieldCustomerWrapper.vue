<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { pick } from 'lodash-es'
import { markRaw } from 'vue'

import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import type { AutoCompleteOption } from '#shared/components/Form/fields/FieldAutocomplete/types.ts'
import { AutocompleteSearchGenericDocument } from '#shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/generic.api.ts'
import type { AutoCompleteCustomerGenericOption } from '#shared/components/Form/fields/FieldCustomer/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import type { User } from '#shared/graphql/types.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import { normalizeEdges } from '#shared/utils/helpers.ts'

import FieldAutoCompleteInput from '../FieldAutoComplete/FieldAutoCompleteInput.vue'
import { useAddUnknownValueAction } from '../FieldAutoComplete/useAddUnknownValueAction.ts'

import FieldCustomerOptionIcon from './FieldCustomerOptionIcon.vue'

import type { AutoCompleteProps } from '../FieldAutoComplete/types.ts'

interface Props {
  context: FormFieldContext<
    AutoCompleteProps & {
      options?: AutoCompleteCustomerGenericOption[]
    }
  >
}

const props = defineProps<Props>()

const buildEntityOption = (entity: User) => {
  return {
    value: entity.internalId,
    label: entity.fullname || entity.phone || entity.login,
    heading: entity.organization?.name,
    user: entity,
  }
}

const { actions, onSearchInteractionUpdate, onKeydownFilterInput } =
  useAddUnknownValueAction()

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

    return buildEntityOption(belongsToObject)
  },
  gqlQuery: AutocompleteSearchGenericDocument,
  additionalQueryParams: {
    onlyIn: ['User', 'Organization'],
  },
  autocompleteOptionsPreprocessor: (
    autocompleteOptions: (AutoCompleteCustomerGenericOption &
      AutoCompleteOption)[],
  ) =>
    autocompleteOptions.map((autocompleteOption) => {
      if (
        !autocompleteOption.object ||
        autocompleteOption.object.__typename !== 'Organization'
      )
        return autocompleteOption

      autocompleteOption.disabled = true

      const heading = autocompleteOption.object.name

      const allMembers = normalizeEdges(autocompleteOption.object.allMembers)

      autocompleteOption.children =
        allMembers.array.map(
          (member) =>
            ({
              value: member.internalId,
              label: member.fullname ?? member.phone ?? member.login,
              heading,
              object: {
                ...member,
                __typename: 'User',

                // Include the current organization only, so the organization field can be automatically pre-filled.
                //   This can potentially be a secondary organization of the user, depending on the current navigation.
                organization: pick(autocompleteOption.object, [
                  '__typename',
                  'id',
                  'internalId',
                  'name',
                  'active',
                ]),
              },
            }) as AutoCompleteOption,
        ) || []

      return autocompleteOption
    }),
  actions,
  emptyInitialLabelText: __(
    'Start typing to search or enter an email address…',
  ),
})
</script>

<template>
  <FieldAutoCompleteInput
    :context="context"
    v-bind="$attrs"
    @search-interaction-update="onSearchInteractionUpdate"
    @keydown-filter-input="onKeydownFilterInput"
  />
</template>
