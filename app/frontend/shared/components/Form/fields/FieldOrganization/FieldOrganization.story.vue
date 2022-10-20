<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKit } from '@formkit/vue'
import { escapeRegExp } from 'lodash-es'
import gql from 'graphql-tag'
import { createMockClient } from 'mock-apollo-client'
import { provideApolloClient } from '@vue/apollo-composable'
import testOptions from '@shared/components/Form/fields/FieldOrganization/__tests__/test-options.json'
import type { AvatarOrganization } from '@shared/components/CommonOrganizationAvatar/types'

const AutocompleteSearchOrganizationDocument = gql`
  query autocompleteSearchOrganization($query: String!, $limit: Int) {
    autocompleteSearchOrganization(query: $query, limit: $limit) {
      value
      label
      labelPlaceholder
      heading
      headingPlaceholder
      disabled
      organization
    }
  }
`

type AutocompleteSearchOrganizationQuery = {
  __typename?: 'Queries'
  autocompleteSearchOrganization: Array<{
    __typename?: 'AutocompleteEntry'
    value: string
    label: string
    labelPlaceholder?: Array<string> | null
    heading?: string | null
    headingPlaceholder?: Array<string> | null
    disabled?: boolean | null
    organization?: AvatarOrganization
  }>
}

const mockQueryResult = (
  query: string,
  limit: number,
): AutocompleteSearchOrganizationQuery => {
  const options = testOptions.map((option) => ({
    ...option,
    labelPlaceholder: null,
    headingPlaceholder: null,
    disabled: null,
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
      filterRegex.test(deaccent(option.heading)),
  ) as unknown as {
    __typename?: 'AutocompleteEntry'
    value: string
    label: string
    labelPlaceholder?: Array<string> | null
    disabled?: boolean | null
    organization?: AvatarOrganization
  }[]

  return {
    autocompleteSearchOrganization: filteredOptions.slice(0, limit ?? 25),
  }
}

const mockClient = () => {
  const mockApolloClient = createMockClient()

  mockApolloClient.setRequestHandler(
    AutocompleteSearchOrganizationDocument,
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
    clearable: false,
    debounceInterval: null,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Organization',
    name: 'organization',
  },
  {
    options: testOptions,
    clearable: false,
    debounceInterval: null,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Initial Options',
    name: 'organization_options',
  },
  {
    options: testOptions,
    clearable: false,
    debounceInterval: null,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Default Value',
    name: 'organization_default_value',
    value: 'Z2lkOi8vemFtbWFkL1VzZXIvMa',
  },
  {
    options: testOptions,
    clearable: true,
    debounceInterval: null,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Clearable Value',
    name: 'organization_clearable',
    value: 'Z2lkOi8vemFtbWFkL1VzZXIvMb',
  },
  {
    options: null,
    clearable: false,
    debounceInterval: null,
    limit: 1,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Query Limit',
    name: 'organization_limit',
  },
  {
    options: testOptions,
    clearable: false,
    debounceInterval: null,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Disabled State',
    name: 'organization_disabled',
    value: 'Z2lkOi8vemFtbWFkL1VzZXIvMc',
    disabled: true,
  },
  {
    options: testOptions,
    clearable: false,
    debounceInterval: null,
    limit: null,
    multiple: true,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Multiple Selection',
    name: 'organization_multiple',
    value: ['Z2lkOi8vemFtbWFkL1VzZXIvMa', 'Z2lkOi8vemFtbWFkL1VzZXIvMc'],
  },
  {
    options: [...testOptions].reverse(),
    clearable: false,
    debounceInterval: null,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: 'label',
    label: 'Option Sorting',
    name: 'organization_sorting',
  },
  {
    options: [
      {
        ...testOptions[0],
        label: `${testOptions[0].label} (%s)`,
        labelPlaceholder: ['1st'],
        heading: `${testOptions[0].heading} (%s)`,
        headingPlaceholder: ['3'],
      },
      {
        ...testOptions[1],
        label: `${testOptions[1].label} (%s)`,
        labelPlaceholder: ['2nd'],
        heading: `${testOptions[1].heading} (%s)`,
        headingPlaceholder: ['3'],
      },
      {
        ...testOptions[2],
        label: `${testOptions[2].label} (%s)`,
        labelPlaceholder: ['3rd'],
        heading: `${testOptions[2].heading} (%s)`,
        headingPlaceholder: ['3'],
      },
    ],
    clearable: false,
    debounceInterval: null,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Option Translation',
    name: 'organization_translation',
  },
  {
    options: [
      testOptions[0],
      testOptions[1],
      {
        ...testOptions[2],
        disabled: true,
      },
    ],
    clearable: false,
    debounceInterval: null,
    limit: null,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Option Disabled',
    name: 'organization_disabled',
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
      <FormKit type="organization" v-bind="variant" />
    </Variant>
  </Story>
</template>
