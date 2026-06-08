// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
import type { AutoCompleteCustomerGenericOption } from '#shared/components/Form/fields/FieldCustomer/types.ts'
import type { User } from '#shared/graphql/types.ts'

export const useFieldCustomerOption = (object: User): AutoCompleteCustomerGenericOption => ({
  value: object.internalId,
  label: (object.fullname || object.phone || object.login) as string,
  heading: object.organization?.name,
  object,
})
