// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { AutocompleteSearchObjectAttributeExternalDataSourceDocument } from '#shared/components/Form/fields/FieldExternalDataSource/graphql/queries/autocompleteSearchObjectAttributeExternalDataSource.api.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

import type { ExternalDataSourceProps } from './types.ts'
import type { AutocompleteSelectValue } from '../FieldAutocomplete/types.ts'
import type { JsonValue } from 'type-fest'
import type { Ref } from 'vue'

export const useFieldExternalDataSourceWrapper = (
  context: Ref<ExternalDataSourceProps['context']>,
) => {
  const additionalQueryParams = () => {
    const additionalQueryParams: Record<string, JsonValue> = {
      object: context.value.object,
      attributeName: context.value.node.name,
    }

    const { searchTemplateRenderContext, formId, object } = context.value

    const templateRenderContext: Record<string, JsonValue> = {}

    // Add the main entity object id from the current object.
    const entityObject = context.value.node.at('$root')?.context
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

  return {
    actionIcon: 'search',

    gqlQuery: AutocompleteSearchObjectAttributeExternalDataSourceDocument,

    additionalQueryParams,

    complexValue: true,

    // use getter to return new value each time
    get clearValue() {
      return {}
    },

    initialOptionBuilder: (_: ObjectLike, value: AutocompleteSelectValue) =>
      value,
  }
}
