// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { flushPromises } from '@vue/test-utils'
import { ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'

import type {
  MentionKnowledgeBaseItem,
  MentionTextItem,
  MentionUserItem,
} from '#shared/components/Form/fields/FieldEditor/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import FieldEditorSuggestionList from '../FieldEditorSuggestionList.vue'

describe('component for rendering suggestions', () => {
  it('renders knowledge base article', () => {
    const items: MentionKnowledgeBaseItem[] = [
      {
        __typename: 'KnowledgeBaseAnswerTranslation',
        id: convertToGraphQLId('KnowledgeBaseAnswerTranslation', 1),
        title: 'Test 1',
        categoryTreeTranslation: [
          {
            __typename: 'KnowledgeBaseCategoryTranslation',
            id: convertToGraphQLId('KnowledgeBaseCategoryTranslation', 1),
            title: 'Category 1.1',
          },
        ],
      },
      {
        __typename: 'KnowledgeBaseAnswerTranslation',
        id: convertToGraphQLId('KnowledgeBaseAnswerTranslation', 2),
        title: 'Test 2',
        categoryTreeTranslation: [
          {
            __typename: 'KnowledgeBaseCategoryTranslation',
            id: convertToGraphQLId('KnowledgeBaseCategoryTranslation', 2),
            title: 'Category 2.1',
          },
          {
            __typename: 'KnowledgeBaseCategoryTranslation',
            id: convertToGraphQLId('KnowledgeBaseCategoryTranslation', 3),
            title: 'Category 2.2',
          },
        ],
      },
    ]

    const view = renderComponent(FieldEditorSuggestionList, {
      props: {
        query: 'test',
        items,
        type: 'knowledge-base',
        command: vi.fn(),
      },
    })

    expect(view.getByRole('option', { name: 'Category 1.1 Test 1' })).toBeInTheDocument()
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
        id: convertToGraphQLId('TextModule', 1),
      },
    ]

    const view = renderComponent(FieldEditorSuggestionList, {
      props: {
        query: 'text',
        items,
        type: 'text',
        command: vi.fn(),
      },
    })

    expect(view.getByRole('option', { name: 'Text Item key' })).toBeInTheDocument()
  })

  it('renders text item with spaces in search query', () => {
    const items: MentionTextItem[] = [
      {
        name: 'the best',
        keywords: 'best',
        renderedContent: 'wishing you all the best',
        id: convertToGraphQLId('TextModule', 1),
      },
    ]

    const view = renderComponent(FieldEditorSuggestionList, {
      props: {
        query: 'the be',
        items,
        type: 'text',
        command: vi.fn(),
      },
    })

    expect(view.getByRole('option', { name: 'the best best' })).toBeInTheDocument()
  })

  it('renders user mention', () => {
    const items: MentionUserItem[] = [
      {
        id: convertToGraphQLId('User', 1),
        fullname: 'John Doe',
        internalId: 1,
        email: 'john@mail.com',
      },
      {
        id: convertToGraphQLId('User', 2),
        fullname: 'Nicole Braun',
        internalId: 2,
      },
    ]

    const view = renderComponent(FieldEditorSuggestionList, {
      props: {
        query: '*',
        items,
        type: 'user',
        command: vi.fn(),
      },
    })

    expect(view.getByRole('option', { name: 'John Doe <john@mail.com>' })).toBeInTheDocument()
    expect(view.getByRole('option', { name: 'Nicole Braun' })).toBeInTheDocument()
  })

  it('renders user mention with spaces in search query', () => {
    const items: MentionUserItem[] = [
      {
        id: convertToGraphQLId('User', 1),
        fullname: 'John Doe',
        internalId: 1,
        email: 'john@mail.com',
      },
      {
        id: convertToGraphQLId('User', 2),
        fullname: 'Nicole Braun',
        internalId: 2,
      },
    ]

    const view = renderComponent(FieldEditorSuggestionList, {
      props: {
        query: 'john mail.com',
        items,
        type: 'user',
        command: vi.fn(),
      },
    })

    expect(view.getByRole('option', { name: 'John Doe <john@mail.com>' })).toBeInTheDocument()
  })
})

describe('actions in list', () => {
  const items: MentionUserItem[] = [
    {
      id: convertToGraphQLId('User', 1),
      fullname: 'John Doe',
      internalId: 1,
    },
    {
      id: convertToGraphQLId('User', 2),
      fullname: 'Nicole Braun',
      internalId: 2,
    },
    {
      id: convertToGraphQLId('User', 3),
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
        components: { FieldEditorSuggestionList },
        template: `<FieldEditorSuggestionList v-bind="$props" ref="listExposed" />`,
        setup: () => ({ listExposed }),
      },
      {
        props: {
          query: '*',
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

    await triggerKey('Tab')

    expect(command).toHaveBeenCalledWith(items[0])
  })
})
