<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { JsonValue } from 'type-fest'
import { defineAsyncComponent } from 'vue'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import type {
  AutoCompleteProps,
  AutocompleteSelectValue,
} from '#shared/components/Form/fields/FieldAutocomplete/types.ts'
import type { AutoCompleteExternalDataSourceOption } from '#shared/components/Form/fields/FieldExternalDataSource/types.ts'
import { AutocompleteSearchObjectAttributeExternalDataSourceDocument } from '#shared/components/Form/fields/FieldExternalDataSource/graphql/queries/autocompleteSearchObjectAttributeExternalDataSource.api.ts'
import type { ObjectLike } from '#shared/types/utils.ts'
import type { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

const FieldAutoCompleteInput = defineAsyncComponent(
  () =>
    import(
      '#mobile/components/Form/fields/FieldAutoComplete/FieldAutoCompleteInput.vue'
    ),
)

interface Props {
  context: FormFieldContext<
    AutoCompleteProps & {
      object: EnumObjectManagerObjects
      options?: AutoCompleteExternalDataSourceOption[]
      searchTemplateRenderContext?: (
        formId: string,
        entityObject: ObjectLike,
      ) => Record<string, string>
    }
  >
}

const props = defineProps<Props>()

const additionalQueryParams = () => {
  const additionalQueryParams: Record<string, JsonValue> = {
    object: props.context.object,
    attributeName: props.context.node.name,
  }

  const { searchTemplateRenderContext, formId, object } = props.context

  const templateRenderContext: Record<string, JsonValue> = {}

  // Add the main entity object id from the current object.
  const entityObject = props.context.node.at('$root')?.context
    ?.initialEntityObject as ObjectLike
  if (entityObject) {
    templateRenderContext[`${object.toLowerCase()}Id`] = entityObject.id
  }

  // Add additional data from the given search context information.
  if (searchTemplateRenderContext) {
    const additionaltemplateRenderContext =
      searchTemplateRenderContext(formId, entityObject) || {}

    Object.assign(templateRenderContext, additionaltemplateRenderContext)
  }

  additionalQueryParams.templateRenderContext = templateRenderContext

  return additionalQueryParams
}

Object.assign(props.context, {
  actionIcon: 'mobile-search',

  gqlQuery: AutocompleteSearchObjectAttributeExternalDataSourceDocument,

  additionalQueryParams,

  complexValue: true,

  // use getter to return new value each time
  get clearValue() {
    return {}
  },

  initialOptionBuilder: (_: ObjectLike, value: AutocompleteSelectValue) =>
    value,
})
</script>

<template>
  <FieldAutoCompleteInput :context="context" v-bind="$attrs" />
</template>
