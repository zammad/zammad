// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '@tests/support/components'
import { flushPromises } from '@vue/test-utils'
import { ref } from 'vue'
import SuggestionsList from '../SuggestionsList.vue'
import type {
  MentionKnowledgeBaseItem,
  MentionTextItem,
  MentionUserItem,
} from '../types'

describe('component for rendering suggestions', () => {
  it('renders knowledge base article', () => {
    const items: MentionKnowledgeBaseItem[] = [
      {
        __typename: 'KnowledgeBaseAnswerTranslation',
        id: btoa('Test 1'),
        title: 'Test 1',
        categoryTreeTranslation: [
          {
            __typename: 'KnowledgeBaseCategoryTranslation',
            id: btoa('Category 1.1'),
            title: 'Category 1.1',
          },
        ],
      },
      {
        __typename: 'KnowledgeBaseAnswerTranslation',
        id: btoa('Test 2'),
        title: 'Test 2',
        categoryTreeTranslation: [
          {
            __typename: 'KnowledgeBaseCategoryTranslation',
            id: btoa('Category 2.1'),
            title: 'Category 2.1',
          },
          {
            __typename: 'KnowledgeBaseCategoryTranslation',
            id: btoa('Category 2.2'),
            title: 'Category 2.2',
          },
        ],
      },
    ]

    const view = renderComponent(SuggestionsList, {
      props: {
        items,
        type: 'knowledge-base',
        command: vi.fn(),
      },
    })

    expect(
      view.getByRole('option', { name: 'Category 1.1 Test 1' }),
    ).toBeInTheDocument()
    expect(
      view.getByRole('option', { name: 'Category 2.1 Category 2.2 Test 2' }),
    ).toBeInTheDocument()
  })

  it('renders text item', () => {
    const items: MentionTextItem[] = [
      {
        name: 'Text Item',
        keywords: 'key',
        renderedContent: 'content',
        id: btoa('Text Item'),
      },
    ]

    const view = renderComponent(SuggestionsList, {
      props: {
        items,
        type: 'text',
        command: vi.fn(),
      },
    })

    expect(
      view.getByRole('option', { name: 'Text Item key' }),
    ).toBeInTheDocument()
  })

  it('renders user mention', () => {
    const items: MentionUserItem[] = [
      {
        id: btoa('John Doe'),
        fullname: 'John Doe',
        internalId: 1,
        email: 'john@mail.com',
      },
      {
        id: btoa('Nicole Braun'),
        fullname: 'Nicole Braun',
        internalId: 2,
      },
    ]

    const view = renderComponent(SuggestionsList, {
      props: {
        items,
        type: 'user',
        command: vi.fn(),
      },
    })

    expect(
      view.getByRole('option', { name: 'John Doe <john@mail.com>' }),
    ).toBeInTheDocument()
    expect(
      view.getByRole('option', { name: 'Nicole Braun' }),
    ).toBeInTheDocument()
  })
})

describe('actions in list', () => {
  const items: MentionUserItem[] = [
    {
      id: btoa('John Doe'),
      fullname: 'John Doe',
      internalId: 1,
    },
    {
      id: btoa('Nicole Braun'),
      fullname: 'Nicole Braun',
      internalId: 2,
    },
    {
      id: btoa('Erik Wise'),
      fullname: 'Erik Wise',
      internalId: 3,
    },
  ]

  const renderList = () => {
    const listExposed = ref<{
      onKeyDown: (e: any) => void
    }>()
    const command = vi.fn()
    const view = renderComponent(
      {
        components: { SuggestionsList },
        template: `<SuggestionsList v-bind="$props" ref="listExposed" />`,
        setup: () => ({ listExposed }),
      },
      {
        props: {
          items,
          type: 'user',
          command,
        },
      },
    )
    const triggerKey = async (key: string) => {
      listExposed.value?.onKeyDown({ event: { key } })

      await flushPromises()
    }

    return {
      view,
      command,
      triggerKey,
    }
  }

  it('can travers with arrow keys', async () => {
    const { view, triggerKey } = renderList()

    const options = view.getAllByRole('option')

    expect(options[0]).toHaveClass('bg-gray-400')

    await triggerKey('ArrowDown')

    expect(options[0]).not.toHaveClass('bg-gray-400')
    expect(options[1]).toHaveClass('bg-gray-400')

    await triggerKey('ArrowDown')

    expect(options[0]).not.toHaveClass('bg-gray-400')
    expect(options[1]).not.toHaveClass('bg-gray-400')
    expect(options[2]).toHaveClass('bg-gray-400')

    await triggerKey('ArrowDown')

    expect(options[0]).toHaveClass('bg-gray-400')
    expect(options[1]).not.toHaveClass('bg-gray-400')
    expect(options[2]).not.toHaveClass('bg-gray-400')

    await triggerKey('ArrowUp')

    expect(options[0]).not.toHaveClass('bg-gray-400')
    expect(options[1]).not.toHaveClass('bg-gray-400')
    expect(options[2]).toHaveClass('bg-gray-400')
  })

  it('selects on enter', async () => {
    const { command, triggerKey } = renderList()

    await triggerKey('Enter')

    expect(command).toHaveBeenCalledWith(items[0])
  })

  it('selects on tab', async () => {
    const { command, triggerKey } = renderList()

    await triggerKey('Enter')

    expect(command).toHaveBeenCalledWith(items[0])
  })
})
