// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
import type { AutoCompleteCustomerGenericOption } from '#shared/components/Form/fields/FieldCustomer/types.ts'
import type { User } from '#shared/graphql/types.ts'

type AutocompleteCustomerUser = Extract<
  NonNullable<AutoCompleteCustomerGenericOption['object']>,
  { __typename: 'User' }
>

export const useFieldCustomerOption = (object: User): AutoCompleteCustomerGenericOption => ({
  __typename: 'AutocompleteSearchGenericEntry',
  value: object.internalId,
  label: (object.fullname || object.phone || object.login) as string,
  labelPlaceholder: null,
  heading: object.organization?.name,
  headingPlaceholder: null,
  disabled: false,
  object: {
    ...object,
    __typename: 'User',
  } as AutocompleteCustomerUser,
})
