<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { markRaw } from 'vue'

import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import { AutocompleteSearchAgentDocument } from '#shared/components/Form/fields/FieldAgent/graphql/queries/autocompleteSearch/agent.api.ts'
import type { AutoCompleteAgentOption } from '#shared/components/Form/fields/FieldAgent/types'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import type { User } from '#shared/graphql/types.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import FieldAutoCompleteInput from '../FieldAutoComplete/FieldAutoCompleteInput.vue'

import FieldAgentOptionIcon from './FieldAgentOptionIcon.vue'

import type { AutoCompleteProps } from '../FieldAutoComplete/types.ts'

interface Props {
  context: FormFieldContext<
    AutoCompleteProps & {
      options?: AutoCompleteAgentOption[]
      exceptUserInternalId?: number
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

Object.assign(props.context, {
  optionIconComponent: markRaw(FieldAgentOptionIcon),
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
  gqlQuery: AutocompleteSearchAgentDocument,
  additionalQueryParams: {
    exceptInternalId: props.context.exceptUserInternalId,
  },
})
</script>

<template>
  <FieldAutoCompleteInput :context="context" v-bind="$attrs" />
</template>
