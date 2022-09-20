// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import { FormKit } from '@formkit/vue'
import { escapeRegExp } from 'lodash-es'
import gql from 'graphql-tag'
import defaultArgTypes from '@stories/support/form/field/defaultArgTypes'
import type { FieldArgs } from '@stories/types/form'
import { createMockClient } from 'mock-apollo-client'
import { provideApolloClient } from '@vue/apollo-composable'
import type { AutoCompleteOption } from '../FieldAutoComplete'

export default {
  title: 'Form/Field/Recipient',
  component: FormKit,
  argTypes: {
    ...defaultArgTypes,
    options: {
      type: { name: 'array', required: true },
      description: 'List of initial recipients',
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
      description: 'Defines GraphQL query for the recipient search',
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

const Template: Story<FieldArgs> = (args: FieldArgs) => ({
  components: { FormKit },
  setup() {
    mockClient()
    return { args }
  },
  template: '<FormKit type="recipient" v-bind="args"/>',
})

export const Default = Template.bind({})
Default.args = {
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
}

export const InitialOptions = Template.bind({})
InitialOptions.args = {
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
}

export const DefaultValue = Template.bind({})
DefaultValue.args = {
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
}

export const ClearableValue = Template.bind({})
ClearableValue.args = {
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
}

export const QueryLimit = Template.bind({})
QueryLimit.args = {
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
}

export const DisabledState = Template.bind({})
DisabledState.args = {
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
}

export const MultipleSelection = Template.bind({})
MultipleSelection.args = {
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
}

export const OptionSorting = Template.bind({})
OptionSorting.args = {
  options: testOptions.reverse(),
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
}

export const OptionTranslation = Template.bind({})
OptionTranslation.args = {
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
}

export const OptionAutoselect = Template.bind({})
OptionAutoselect.args = {
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
}

export const OptionDisabled = Template.bind({})
OptionDisabled.args = {
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
}

export const OptionIcon = Template.bind({})
OptionIcon.args = {
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
}

export const AdditionalAction = Template.bind({})
AdditionalAction.args = {
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
}
