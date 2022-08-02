// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import { FormKit } from '@formkit/vue'
import { escapeRegExp } from 'lodash-es'
import defaultArgTypes from '@stories/support/form/field/defaultArgTypes'
import type { FieldArgs } from '@stories/types/form'
import { createMockClient } from 'mock-apollo-client'
import { provideApolloClient } from '@vue/apollo-composable'
import type { AutocompleteSearchUserQuery } from '@shared/graphql/types'
import { AutocompleteSearchUserDocument } from '@shared/graphql/queries/autocompleteSearch/user.api'

export default {
  title: 'Form/Field/AutoComplete',
  component: FormKit,
  argTypes: {
    ...defaultArgTypes,
    options: {
      type: { name: 'array', required: true },
      description: 'List of initial autocomplete options',
      table: {
        expanded: true,
        type: {
          summary: 'AutoCompleteOption[]',
          detail: `{
  value: string | number
  label: string
  labelPlaceholder?: string[]
  heading?: string
  headingPlaceholder?: string[]
  disabled?: boolean
  icon?: string
}`,
        },
      },
    },
    action: {
      description: 'Defines route for an optional action button in the dialog',
    },
    actionIcon: {
      description: 'Defines optional icon for the action button in the dialog',
    },
    autoselect: {
      description:
        'Automatically selects last option when and only when option list length equals one',
    },
    clearable: {
      description: 'Allows clearing of selected values',
    },
    debounceInterval: {
      description:
        'Defines interval for debouncing search input (default: 500)',
    },
    gqlQuery: {
      description: 'Defines GraphQL query for the autocomplete search',
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
    optionIconComponent: {
      type: { name: 'Component', required: false },
      description:
        'Controls which type of icon component will be used for options',
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

const testOptions = [
  {
    value: 0,
    label: 'Item A',
    icon: 'gitlab-logo',
    heading: 'autocomplete sample 1',
  },
  {
    value: 1,
    label: 'Item B',
    icon: 'github-logo',
    heading: 'autocomplete sample 2',
  },
  {
    value: 2,
    label: 'Ítem C',
    icon: 'web',
    heading: 'autocomplete sample 3',
  },
]

const gqlQuery = `
  query autocompleteSearchUser($query: String!, $limit: Int) {
    autocompleteSearchUser(query: $query, limit: $limit) {
      value
      label
      labelPlaceholder
      disabled
      icon
    }
  }
`

const mockQueryResult = (
  query: string,
  limit: number,
): AutocompleteSearchUserQuery => {
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
  const filteredOptions = options.filter((option) =>
    filterRegex.test(deaccent(option.label)),
  ) as unknown as {
    __typename?: 'AutocompleteEntry'
    value: string
    label: string
    labelPlaceholder?: Array<string> | null
    disabled?: boolean | null
    icon?: string | null
  }[]

  return {
    autocompleteSearchUser: filteredOptions.slice(0, limit ?? 25),
  }
}

const mockClient = () => {
  const mockApolloClient = createMockClient()

  mockApolloClient.setRequestHandler(
    AutocompleteSearchUserDocument,
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
  template: '<FormKit type="autocomplete" v-bind="args"/>',
})

export const Default = Template.bind({})
Default.args = {
  options: null,
  action: null,
  actionIcon: null,
  autoselect: false,
  clearable: false,
  gqlQuery,
  limit: null,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Auto Complete',
  name: 'autocomplete',
}

export const InitialOptions = Template.bind({})
InitialOptions.args = {
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
  autoselect: false,
  clearable: false,
  gqlQuery,
  limit: null,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Initial Options',
  name: 'autocomplete_options',
}

export const DefaultValue = Template.bind({})
DefaultValue.args = {
  options: null,
  action: null,
  actionIcon: null,
  autoselect: false,
  clearable: false,
  gqlQuery,
  limit: null,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Default Value',
  name: 'autocomplete_default_value',
  value: 0,
}

export const ClearableValue = Template.bind({})
ClearableValue.args = {
  options: testOptions,
  action: null,
  actionIcon: null,
  autoselect: false,
  clearable: true,
  gqlQuery,
  limit: null,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Clearable Value',
  name: 'autocomplete_clearable',
  value: 1,
}

export const QueryLimit = Template.bind({})
QueryLimit.args = {
  options: null,
  action: null,
  actionIcon: null,
  autoselect: false,
  clearable: false,
  gqlQuery,
  limit: 1,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Query Limit',
  name: 'autocomplete_limit',
}

export const DisabledState = Template.bind({})
DisabledState.args = {
  options: testOptions,
  action: null,
  actionIcon: null,
  autoselect: false,
  clearable: false,
  gqlQuery,
  limit: null,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Disabled State',
  name: 'autocomplete_disabled',
  value: 2,
  disabled: true,
}

export const MultipleSelection = Template.bind({})
MultipleSelection.args = {
  options: testOptions,
  action: null,
  actionIcon: null,
  autoselect: false,
  clearable: false,
  gqlQuery,
  limit: null,
  multiple: true,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Multiple Selection',
  name: 'autocomplete_multiple',
  value: [0, 2],
}

export const OptionSorting = Template.bind({})
OptionSorting.args = {
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
  autoselect: false,
  clearable: false,
  gqlQuery,
  limit: null,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: 'label',
  label: 'Option Sorting',
  name: 'autocomplete_sorting',
}

export const OptionTranslation = Template.bind({})
OptionTranslation.args = {
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
  autoselect: false,
  clearable: false,
  gqlQuery,
  limit: null,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Option Translation',
  name: 'autocomplete_translation',
}

export const OptionAutoselect = Template.bind({})
OptionAutoselect.args = {
  options: [
    {
      value: 1,
      label: 'The One',
    },
  ],
  action: null,
  actionIcon: null,
  autoselect: true,
  clearable: false,
  gqlQuery,
  limit: null,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Option Autoselect',
  name: 'autocomplete_autoselect',
}

export const OptionDisabled = Template.bind({})
OptionDisabled.args = {
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
  autoselect: false,
  clearable: false,
  gqlQuery,
  limit: null,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Option Disabled',
  name: 'autocomplete_disabled',
}

export const OptionIcon = Template.bind({})
OptionIcon.args = {
  options: [
    {
      value: 1,
      label: 'GitLab',
      icon: 'gitlab-logo',
    },
    {
      value: 2,
      label: 'GitHub',
      icon: 'github-logo',
    },
  ],
  action: null,
  actionIcon: null,
  autoselect: false,
  clearable: false,
  gqlQuery,
  limit: null,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Option Icon',
  name: 'autocomplete_icon',
}

export const AdditionalAction = Template.bind({})
AdditionalAction.args = {
  options: null,
  action: '/tickets',
  actionIcon: 'web',
  autoselect: false,
  clearable: false,
  gqlQuery,
  limit: null,
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Additional Action',
  name: 'autocomplete_action',
}
