// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import { FormKit } from '@formkit/vue'
import { escapeRegExp } from 'lodash-es'
import gql from 'graphql-tag'
import defaultArgTypes from '@stories/support/form/field/defaultArgTypes'
import { createMockClient } from 'mock-apollo-client'
import { provideApolloClient } from '@vue/apollo-composable'
import testOptions from '@shared/components/Form/fields/FieldOrganization/__tests__/test-options.json'
import type { FieldArgs } from '@stories/types/form'
import type { AvatarOrganization } from '@shared/components/CommonOrganizationAvatar/types'

export default {
  title: 'Form/Field/Organization',
  component: FormKit,
  argTypes: {
    ...defaultArgTypes,
    options: {
      type: { name: 'array', required: true },
      description: 'List of initial organizations',
      table: {
        expanded: true,
        type: {
          summary: 'AutoCompleteOrganizationOption[]',
          detail: `{
  value: string | number
  label: string
  labelPlaceholder?: string[]
  heading?: string
  headingPlaceholder?: string[]
  disabled?: boolean
  organization?: AvatarOrganization
}`,
        },
      },
    },
    autoselect: {
      description:
        'Automatically selects last option when and only when option list length equals one',
    },
    clearable: {
      debounceInterval: null,
      description: 'Allows clearing of selected values',
    },
    debounceInterval: {
      description:
        'Defines interval for debouncing search input (default: 500)',
    },
    limit: {
      description: 'Controls maximum number of results',
    },
    multiple: {
      description: 'Allows multi selection',
    },
    noOptionsLabelTranslation: {
      description: 'Skips translation of option labels',
    },
    sorting: {
      type: { name: 'string', required: false },
      description: 'Sorts options by property',
      table: {
        type: {
          summary: "'label' | 'value'",
        },
      },
      options: [undefined, 'label', 'value'],
      control: {
        type: 'select',
      },
    },
  },
}

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

const Template: Story<FieldArgs> = (args: FieldArgs) => ({
  components: { FormKit },
  setup() {
    mockClient()
    return { args }
  },
  template: '<FormKit type="organization" v-bind="args"/>',
})

export const Default = Template.bind({})
Default.args = {
  options: null,
  autoselect: false,
  clearable: false,
  debounceInterval: null,
  limit: null,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Organization',
  name: 'organization',
}

export const InitialOptions = Template.bind({})
InitialOptions.args = {
  options: testOptions,
  autoselect: false,
  clearable: false,
  debounceInterval: null,
  limit: null,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Initial Options',
  name: 'organization_options',
}

export const DefaultValue = Template.bind({})
DefaultValue.args = {
  options: testOptions,
  autoselect: false,
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
}

export const ClearableValue = Template.bind({})
ClearableValue.args = {
  options: testOptions,
  autoselect: false,
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
}

export const QueryLimit = Template.bind({})
QueryLimit.args = {
  options: null,
  autoselect: false,
  clearable: false,
  debounceInterval: null,
  limit: 1,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Query Limit',
  name: 'organization_limit',
}

export const DisabledState = Template.bind({})
DisabledState.args = {
  options: testOptions,
  autoselect: false,
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
}

export const MultipleSelection = Template.bind({})
MultipleSelection.args = {
  options: testOptions,
  autoselect: false,
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
}

export const OptionSorting = Template.bind({})
OptionSorting.args = {
  options: [...testOptions].reverse(),
  autoselect: false,
  clearable: false,
  debounceInterval: null,
  limit: null,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: 'label',
  label: 'Option Sorting',
  name: 'organization_sorting',
}

export const OptionTranslation = Template.bind({})
OptionTranslation.args = {
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
  autoselect: false,
  clearable: false,
  debounceInterval: null,
  limit: null,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Option Translation',
  name: 'organization_translation',
}

export const OptionAutoselect = Template.bind({})
OptionAutoselect.args = {
  options: [testOptions[0]],
  autoselect: true,
  clearable: false,
  debounceInterval: null,
  limit: null,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Option Autoselect',
  name: 'organization_autoselect',
}

export const OptionDisabled = Template.bind({})
OptionDisabled.args = {
  options: [
    testOptions[0],
    testOptions[1],
    {
      ...testOptions[2],
      disabled: true,
    },
  ],
  autoselect: false,
  clearable: false,
  debounceInterval: null,
  limit: null,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Option Disabled',
  name: 'organization_disabled',
}
