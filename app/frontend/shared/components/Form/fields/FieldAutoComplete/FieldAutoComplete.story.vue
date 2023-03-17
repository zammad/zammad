<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKit } from '@formkit/vue'
import { AutocompleteSearchUserDocument } from '@shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/user.api'
import { createMockClient } from 'mock-apollo-client'
import { provideApolloClient } from '@vue/apollo-composable'
import type { AutocompleteSearchUserQuery, User } from '@shared/graphql/types'
import { escapeRegExp } from 'lodash-es'

const testOptions = [
  {
    value: 0,
    label: 'Item A',
    icon: 'mobile-gitlab',
    heading: 'autocomplete sample 1',
  },
  {
    value: 1,
    label: 'Item B',
    icon: 'mobile-github',
    heading: 'autocomplete sample 2',
  },
  {
    value: 2,
    label: 'Ítem C',
    icon: 'mobile-web',
    heading: 'autocomplete sample 3',
  },
]

const mockQueryResult = (input: {
  query: string
  limit: number
}): AutocompleteSearchUserQuery => {
  const options = testOptions.map((option) => ({
    ...option,
    labelPlaceholder: null,
    headingPlaceholder: null,
    disabled: null,
    user: {
      firstname: null,
    } as User,
    __typename: 'AutocompleteUserEntry',
  }))

  const deaccent = (s: string) =>
    s.normalize('NFD').replace(/[\u0300-\u036f]/g, '')

  // Trim and de-accent search keywords and compile them as a case-insensitive regex.
  //   Make sure to escape special regex characters!
  const filterRegex = new RegExp(escapeRegExp(deaccent(input.query)), 'i')

  // Search across options via their de-accented labels.
  const filteredOptions = options.filter((option) =>
    filterRegex.test(deaccent(option.label)),
  ) as unknown as AutocompleteSearchUserQuery['autocompleteSearchUser']

  return {
    autocompleteSearchUser: filteredOptions.slice(0, input.limit ?? 25),
  }
}

const mockClient = () => {
  const mockApolloClient = createMockClient()

  mockApolloClient.setRequestHandler(
    AutocompleteSearchUserDocument,
    (variables) => {
      return Promise.resolve({
        data: mockQueryResult(variables.input),
      })
    },
  )

  provideApolloClient(mockApolloClient)
}

mockClient()

const gqlQuery = `
  query autocompleteSearchUser($input: AutocompleteSearchInput!) {
    autocompleteSearchUser(input: $input) {
      value
      label
      labelPlaceholder
      heading
      headingPlaceholder
      disabled
      icon
      user {
        id
        fullname
      }
    }
  }
`

const variants = [
  {
    options: null,
    action: null,
    actionIcon: null,
    clearable: false,
    gqlQuery,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Auto Complete',
    name: 'autocomplete',
  },
  {
    options: [
      {
        value: 0,
        label: 'Item A',
      },
      {
        value: 1,
        label: 'Item B',
      },
      {
        value: 2,
        label: 'Item C',
      },
    ],
    action: null,
    actionIcon: null,
    clearable: false,
    gqlQuery,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Initial Options',
    name: 'autocomplete_options',
  },
  {
    options: null,
    action: null,
    actionIcon: null,
    clearable: false,
    gqlQuery,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Default Value',
    name: 'autocomplete_default_value',
    value: 0,
  },
  {
    options: testOptions,
    action: null,
    actionIcon: null,
    clearable: true,
    gqlQuery,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Clearable Value',
    name: 'autocomplete_clearable',
    value: 1,
  },
  {
    options: null,
    action: null,
    actionIcon: null,
    clearable: false,
    gqlQuery,
    limit: 1,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Query Limit',
    name: 'autocomplete_limit',
  },
  {
    options: testOptions,
    action: null,
    actionIcon: null,
    clearable: false,
    gqlQuery,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Disabled State',
    name: 'autocomplete_disabled',
    value: 2,
    disabled: true,
  },
  {
    options: testOptions,
    action: null,
    actionIcon: null,
    clearable: false,
    gqlQuery,
    limit: null,
    multiple: true,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Multiple Selection',
    name: 'autocomplete_multiple',
    value: [0, 2],
  },
  {
    options: [
      {
        value: 1,
        label: 'Item B',
      },
      {
        value: 2,
        label: 'Item C',
      },
      {
        value: 0,
        label: 'Item A',
      },
    ],
    action: null,
    actionIcon: null,
    clearable: false,
    gqlQuery,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: 'label',
    label: 'Option Sorting',
    name: 'autocomplete_sorting',
  },
  {
    options: [
      {
        value: 0,
        label: 'Item A (%s)',
        labelPlaceholder: ['1st'],
      },
      {
        value: 1,
        label: 'Item B (%s)',
        labelPlaceholder: ['2nd'],
      },
      {
        value: 2,
        label: 'Item C (%s)',
        labelPlaceholder: ['3rd'],
      },
    ],
    action: null,
    actionIcon: null,
    clearable: false,
    gqlQuery,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Option Translation',
    name: 'autocomplete_translation',
  },
  {
    options: [
      {
        value: 0,
        label: 'Item A',
      },
      {
        value: 1,
        label: 'Item B',
        disabled: true,
      },
      {
        value: 2,
        label: 'Item C',
      },
    ],
    action: null,
    actionIcon: null,
    clearable: false,
    gqlQuery,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Option Disabled',
    name: 'autocomplete_disabled',
  },
  {
    options: [
      {
        value: 1,
        label: 'GitLab',
        icon: 'mobile-gitlab',
      },
      {
        value: 2,
        label: 'GitHub',
        icon: 'mobile-github',
      },
    ],
    action: null,
    actionIcon: null,
    clearable: false,
    gqlQuery,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Option Icon',
    name: 'autocomplete_icon',
  },
  {
    options: null,
    action: '/tickets',
    actionIcon: 'mobile-web',
    clearable: false,
    gqlQuery,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Additional Action',
    name: 'autocomplete_action',
  },
] as any
</script>

<template>
  <Story>
    <Variant
      v-for="(variant, name) in variants"
      :key="name"
      :title="variant.label"
    >
      <FormKit type="autocomplete" v-bind="variant" />
    </Variant>
  </Story>
</template>
