// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { AutoCompleteProps } from '#shared/components/Form/fields/FieldAutocomplete/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import type {
  AutocompleteSearchObjectAttributeExternalDataSourceQuery,
  EnumObjectManagerObjects,
} from '#shared/graphql/types.ts'
import type { ConfidentTake, ObjectLike } from '#shared/types/utils.ts'

export type AutoCompleteExternalDataSourceOption = ConfidentTake<
  AutocompleteSearchObjectAttributeExternalDataSourceQuery,
  'autocompleteSearchObjectAttributeExternalDataSource'
>[number]

export interface ExternalDataSourceProps {
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
