// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import type { AutocompleteOrganizationProps } from '#shared/components/Form/fields/FieldOrganization/types.ts'
import { getAutoCompleteOption } from '#shared/entities/organization/utils/getAutoCompleteOption.ts'
import type { Organization } from '#shared/graphql/types.ts'
import type { ObjectLike } from '#shared/types/utils.ts'

export const useFormFieldOrganizationInitialOptionBuilder = () => {
  return (
    initialEntityObject: ObjectLike,
    value: SelectValue,
    context: AutocompleteOrganizationProps['context'],
  ) => {
    if (!context.belongsToObjectField || !initialEntityObject) return null

    const belongsToObject = initialEntityObject[
      context.belongsToObjectField
    ] as Organization

    if (!belongsToObject) return null

    return getAutoCompleteOption(belongsToObject)
  }
}
