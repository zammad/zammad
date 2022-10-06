<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKit } from '@formkit/vue'
import { escapeRegExp } from 'lodash-es'
import gql from 'graphql-tag'
import { createMockClient } from 'mock-apollo-client'
import { provideApolloClient } from '@vue/apollo-composable'
import type { AutoCompleteOption } from '../FieldAutoComplete'

const AutocompleteSearchRecipientDocument = gql`
  query autocompleteSearchRecipient($query: String!, $limit: Int) {
    autocompleteSearchRecipient(query: $query, limit: $limit) {
      value
      label
      labelPlaceholder
      heading
      headingPlaceholder
      disabled
      icon
    }
  }
`

type AutocompleteSearchRecipientQuery = {
  __typename?: 'Queries'
  autocompleteSearchRecipient: Array<{
    __typename?: 'AutocompleteEntry'
    value: string
    label: string
    labelPlaceholder?: Array<string> | null
    heading?: string | null
    headingPlaceholder?: Array<string> | null
    disabled?: boolean | null
    icon?: string | null
  }>
}

const testOptions: AutoCompleteOption[] = [
  {
    value: 'baz@bar.tld',
    label: 'Baz',
    heading: 'baz@bar.tld',
  },
  {
    value: 'qux@bar.tld',
    label: 'Qux',
    heading: 'qux@bar.tld',
  },
  {
    value: 'corge@bar.tld',
    label: 'Corge',
    heading: 'corge@bar.tld',
  },
]

const mockQueryResult = (
  query: string,
  limit: number,
): AutocompleteSearchRecipientQuery => {
  const options = testOptions.map((option) => ({
    ...option,
    labelPlaceholder: null,
    headingPlaceholder: null,
    disabled: null,
    icon: null,
    __typename: 'AutocompleteEntry',
  }))

  const deaccent = (s: string) =>
    s.normalize('NFD').replace(/[\u0300-\u036f]/g, '')

  // Trim and de-accent search keywords and compile them as a case-insensitive regex.
  //   Make sure to escape special regex characters!
  const filterRegex = new RegExp(escapeRegExp(deaccent(query)), 'i')

  // Search across options via their de-accented labels.
  const filteredOptions = options.filter(
    (option) =>
      filterRegex.test(deaccent(option.label)) ||
      filterRegex.test(deaccent(option.heading as string)),
  ) as unknown as {
    __typename?: 'AutocompleteEntry'
    value: string
    label: string
    labelPlaceholder?: Array<string> | null
    disabled?: boolean | null
    icon?: string | null
  }[]

  return {
    autocompleteSearchRecipient: filteredOptions.slice(0, limit ?? 25),
  }
}

const mockClient = () => {
  const mockApolloClient = createMockClient()

  mockApolloClient.setRequestHandler(
    AutocompleteSearchRecipientDocument,
    (variables) => {
      return Promise.resolve({
        data: mockQueryResult(variables.query, variables.limit),
      })
    },
  )

  provideApolloClient(mockApolloClient)
}

mockClient()

const variants = [
  {
    options: null,
    action: null,
    actionIcon: null,
    autoselect: false,
    clearable: false,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Recipient',
    name: 'recipient',
  },
  {
    options: testOptions,
    action: null,
    actionIcon: null,
    autoselect: false,
    clearable: false,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Initial Options',
    name: 'recipient_options',
  },
  {
    options: null,
    action: null,
    actionIcon: null,
    autoselect: false,
    clearable: false,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Default Value',
    name: 'recipient_default_value',
    value: 'corge@bar.tld',
  },
  {
    options: testOptions,
    action: null,
    actionIcon: null,
    autoselect: false,
    clearable: true,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Clearable Value',
    name: 'recipient_clearable',
    value: 'qux@bar.tld',
  },
  {
    options: null,
    action: null,
    actionIcon: null,
    autoselect: false,
    clearable: false,
    limit: 1,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Query Limit',
    name: 'recipient_limit',
  },
  {
    options: testOptions,
    action: null,
    actionIcon: null,
    autoselect: false,
    clearable: false,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Disabled State',
    name: 'recipient_disabled',
    value: 'baz@bar.tld',
    disabled: true,
  },
  {
    options: testOptions,
    action: null,
    actionIcon: null,
    autoselect: false,
    clearable: false,
    limit: null,
    multiple: true,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Multiple Selection',
    name: 'recipient_multiple',
    value: ['baz@bar.tld', 'corge@bar.tld'],
  },
  {
    options: [...testOptions].reverse(),
    action: null,
    actionIcon: null,
    autoselect: false,
    clearable: false,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: 'label',
    label: 'Option Sorting',
    name: 'recipient_sorting',
  },
  {
    options: [
      {
        value: 'baz@bar.tld',
        label: 'Baz (%s)',
        labelPlaceholder: ['1st'],
        heading: 'baz@bar.tld',
      },
      {
        value: 'qux@bar.tld',
        label: 'Qux (%s)',
        labelPlaceholder: ['2nd'],
        heading: 'qux@bar.tld',
      },
      {
        value: 'corge@bar.tld',
        label: 'Corge (%s)',
        labelPlaceholder: ['3rd'],
        heading: 'corge@bar.tld',
      },
    ],
    action: null,
    actionIcon: null,
    autoselect: false,
    clearable: false,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Option Translation',
    name: 'recipient_translation',
  },
  {
    options: [
      {
        value: 'foo@bar.tld',
        label: 'Foo',
        heading: 'foo@bar.tld',
      },
    ],
    action: null,
    actionIcon: null,
    autoselect: true,
    clearable: false,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Option Autoselect',
    name: 'recipient_autoselect',
  },
  {
    options: [
      {
        value: 'baz@bar.tld',
        label: 'Baz',
        heading: 'baz@bar.tld',
      },
      {
        value: 'qux@bar.tld',
        label: 'Qux',
        heading: 'qux@bar.tld',
        disabled: true,
      },
      {
        value: 'corge@bar.tld',
        label: 'Corge',
        heading: 'corge@bar.tld',
      },
    ],
    action: null,
    actionIcon: null,
    autoselect: false,
    clearable: false,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Option Disabled',
    name: 'recipient_disabled',
  },
  {
    options: [
      {
        value: 'baz@bar.tld',
        label: 'Baz',
        heading: 'baz@bar.tld',
        icon: 'email',
      },
      {
        value: 'qux@bar.tld',
        label: 'Qux',
        heading: 'qux@bar.tld',
        icon: 'email',
      },
      {
        value: 'corge@bar.tld',
        label: 'Corge',
        heading: 'corge@bar.tld',
        icon: 'email',
      },
    ],
    action: null,
    actionIcon: null,
    autoselect: false,
    clearable: false,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Option Icon',
    name: 'recipient_icon',
  },
  {
    options: null,
    action: '/tickets',
    actionIcon: 'web',
    autoselect: false,
    clearable: false,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Additional Action',
    name: 'recipient_action',
  },
] as any
</script>

<template>
  <Story>
    <Variant
      v-for="(variant, idx) in variants"
      :key="idx"
      :title="variant.label"
    >
      <FormKit type="recipient" v-bind="variant" />
    </Variant>
  </Story>
</template>
