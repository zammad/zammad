// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'
import { waitFor } from '@testing-library/vue'

import { getByIconName } from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'

import {
  mockAutocompleteSearchKnowledgeBaseAnswerQuery,
  waitForAutocompleteSearchKnowledgeBaseAnswerQueryCalls,
} from '#desktop/entities/knowledge-base/graphql/queries/autocompleteSearch.mocks.ts'

import { testOptions } from './support/testOptions.ts'

const wrapperParameters = {
  form: true,
  router: true,
  dialog: true,
  store: true,
}

const testProps = {
  type: 'knowledgeBaseAnswer',
  label: 'Select…',
}

describe('Form - Field - KnowledgeBase - Query', () => {
  it('fetches remote knowledge base answers via GraphQL query', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    expect(filterElement).toBeInTheDocument()
    expect(wrapper.queryByText('Start typing to search…')).toBeInTheDocument()

    mockAutocompleteSearchKnowledgeBaseAnswerQuery({
      autocompleteSearchKnowledgeBaseAnswer: testOptions,
    })

    await wrapper.events.type(filterElement, 'password')

    await waitForAutocompleteSearchKnowledgeBaseAnswerQueryCalls()

    expect(wrapper.queryByText('Start typing to search…')).not.toBeInTheDocument()

    const selectOptions = wrapper.getAllByTestId('select-item')

    expect(selectOptions).toHaveLength(2)
    expect(selectOptions[0]).toHaveTextContent(
      `${testOptions[0].label} – ${testOptions[0].heading}`,
    )
    expect(getByIconName(selectOptions[0], 'kb-published')).toBeInTheDocument()
    expect(getByIconName(selectOptions[1], 'kb-draft')).toBeInTheDocument()
  })

  it('emits the selected answer id', async () => {
    const wrapper = renderComponent(FormKit, {
      ...wrapperParameters,
      props: {
        ...testProps,
        debounceInterval: 0,
      },
    })

    await wrapper.events.click(await wrapper.findByLabelText('Select…'))

    const filterElement = wrapper.getByRole('searchbox')

    mockAutocompleteSearchKnowledgeBaseAnswerQuery({
      autocompleteSearchKnowledgeBaseAnswer: testOptions,
    })

    await wrapper.events.type(filterElement, 'password')

    await waitForAutocompleteSearchKnowledgeBaseAnswerQueryCalls()

    wrapper.events.click(wrapper.getAllByRole('option')[0])

    await waitFor(() => {
      expect(wrapper.emitted().inputRaw).toBeTruthy()
    })

    const emittedInput = wrapper.emitted().inputRaw as Array<Array<InputEvent>>

    expect(emittedInput[0][0]).toBe(testOptions[0].value)

    expect(wrapper.getByRole('listitem')).toHaveTextContent(testOptions[0].label)
  })
})
