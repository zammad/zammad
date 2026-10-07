// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { flushPromises } from '@vue/test-utils'
import { ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { nullableMock } from '#tests/support/utils.ts'

import type {
  MentionKnowledgeBaseItem,
  MentionKnowledgeBaseRelatedItem,
  MentionTextItem,
  MentionUserItem,
} from '#shared/components/Form/fields/FieldEditor/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import FieldEditorSuggestionList from '../FieldEditorSuggestionList.vue'

import type { PossibleItem } from '../FieldEditorSuggestionList/types.ts'

const baseProps = {
  label: 'Suggestions',
  placeholder: 'Start typing to search…',
  listboxId: 'mention-listbox-test',
}

describe('component for rendering suggestions', () => {
  it('renders knowledge base article', () => {
    const items = nullableMock<MentionKnowledgeBaseItem[]>([
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
      {
        __typename: 'KnowledgeBaseAnswerTranslation',
        id: convertToGraphQLId('KnowledgeBaseAnswerTranslation', 3),
        title: 'Test 3',
        categoryTreeTranslation: [
          {
            __typename: 'KnowledgeBaseCategoryTranslation',
            id: convertToGraphQLId('KnowledgeBaseCategoryTranslation', 4),
            title: 'Category 3.1',
          },
          {
            __typename: 'KnowledgeBaseCategoryTranslation',
            id: convertToGraphQLId('KnowledgeBaseCategoryTranslation', 5),
            title: 'Category 3.2',
          },
          {
            __typename: 'KnowledgeBaseCategoryTranslation',
            id: convertToGraphQLId('KnowledgeBaseCategoryTranslation', 6),
            title: 'Category 3.3',
          },
        ],
      },
    ])

    const view = renderComponent(FieldEditorSuggestionList, {
      props: {
        query: 'test',
        items,
        type: 'knowledge-base',
        command: vi.fn(),
        ...baseProps,
      },
    })

    expect(view.getByRole('option', { name: 'Category 1.1Test 1' })).toBeInTheDocument()

    expect(
      view.getByRole('option', { name: 'Category 2.1 › Category 2.2Test 2' }),
    ).toBeInTheDocument()

    expect(
      view.getByRole('option', { name: 'Category 3.1 › … › Category 3.3Test 3' }),
    ).toBeInTheDocument()
  })

  it('renders text item', () => {
    const items = nullableMock<MentionTextItem[]>([
      {
        name: 'Text Item',
        keywords: 'key',
        renderedContent: 'content',
        id: convertToGraphQLId('TextModule', 1),
      },
    ])

    const view = renderComponent(FieldEditorSuggestionList, {
      props: {
        query: 'text',
        items,
        type: 'text',
        command: vi.fn(),
        ...baseProps,
      },
    })

    expect(view.getByRole('option', { name: 'Text Itemkey' })).toBeInTheDocument()
  })

  it('renders text item with spaces in search query', () => {
    const items = nullableMock<MentionTextItem[]>([
      {
        name: 'the best',
        keywords: 'best',
        renderedContent: 'wishing you all the best',
        id: convertToGraphQLId('TextModule', 1),
      },
    ])

    const view = renderComponent(FieldEditorSuggestionList, {
      props: {
        query: 'the be',
        items,
        type: 'text',
        command: vi.fn(),
        ...baseProps,
      },
    })

    expect(view.getByRole('option', { name: 'the bestbest' })).toBeInTheDocument()
  })

  it('renders user mention', () => {
    const items = nullableMock<MentionUserItem[]>([
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
    ])

    const view = renderComponent(FieldEditorSuggestionList, {
      props: {
        query: '*',
        items,
        type: 'user',
        command: vi.fn(),
        ...baseProps,
      },
    })

    expect(
      view.getByRole('option', { name: 'Avatar (John Doe) John Doe– john@mail.com' }),
    ).toBeInTheDocument()

    expect(
      view.getByRole('option', { name: 'Avatar (Nicole Braun) Nicole Braun' }),
    ).toBeInTheDocument()
  })

  it('renders user mention with spaces in search query', () => {
    const items = nullableMock<MentionUserItem[]>([
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
    ])

    const view = renderComponent(FieldEditorSuggestionList, {
      props: {
        query: 'john mail.com',
        items,
        type: 'user',
        command: vi.fn(),
        ...baseProps,
      },
    })

    expect(
      view.getByRole('option', { name: 'Avatar (John Doe) John Doe– john@mail.com' }),
    ).toBeInTheDocument()
  })
})

describe('actions in list', () => {
  const items = nullableMock<MentionUserItem[]>([
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
  ])

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
          ...baseProps,
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

    const backgroundClasses = ['bg-blue-600', 'dark:bg-blue-900']

    expect(options[0]).toHaveClasses(backgroundClasses)

    await triggerKey('ArrowDown')

    expect(options[0]).not.toHaveClasses(backgroundClasses)
    expect(options[1]).toHaveClasses(backgroundClasses)

    await triggerKey('ArrowDown')

    expect(options[0]).not.toHaveClasses(backgroundClasses)
    expect(options[0]).not.toHaveClasses(backgroundClasses)
    expect(options[2]).toHaveClasses(backgroundClasses)

    await triggerKey('ArrowDown')

    expect(options[0]).toHaveClasses(backgroundClasses)
    expect(options[1]).not.toHaveClasses(backgroundClasses)
    expect(options[2]).not.toHaveClasses(backgroundClasses)

    await triggerKey('ArrowUp')

    expect(options[0]).not.toHaveClasses(backgroundClasses)
    expect(options[1]).not.toHaveClasses(backgroundClasses)
    expect(options[2]).toHaveClasses(backgroundClasses)
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

describe('accessibility (combobox + listbox wiring)', () => {
  const items = nullableMock<MentionTextItem[]>([
    {
      name: 'Greeting',
      keywords: 'hi',
      renderedContent: 'Hello',
      id: convertToGraphQLId('TextModule', 1),
    },
    {
      name: 'Farewell',
      keywords: 'bye',
      renderedContent: 'Goodbye',
      id: convertToGraphQLId('TextModule', 2),
    },
  ])

  it('uses the label prop as the listbox aria-label', () => {
    const view = renderComponent(FieldEditorSuggestionList, {
      props: {
        query: 'g',
        items,
        type: 'text',
        command: vi.fn(),
        ...baseProps,
        label: 'Text modules',
      },
    })

    expect(view.getByRole('listbox', { name: 'Text modules' })).toBeInTheDocument()
  })

  it('shows loading instead of "no results" while the user is still typing', async () => {
    const view = renderComponent(FieldEditorSuggestionList, {
      props: { query: 'a', items: [], type: 'text', command: vi.fn(), ...baseProps },
    })

    expect(view.getByText('No results found')).toBeInTheDocument()

    // Typing another character changes the query → treated as "still typing".
    await view.rerender({ query: 'ab', items: [], type: 'text', command: vi.fn(), ...baseProps })

    expect(view.queryByText('No results found')).not.toBeInTheDocument()
    expect(view.getByText('Loading…')).toBeInTheDocument()
  })

  it('uses the listboxId prop to scope option ids', () => {
    const view = renderComponent(FieldEditorSuggestionList, {
      props: {
        query: 'g',
        items,
        type: 'text',
        command: vi.fn(),
        ...baseProps,
        listboxId: 'custom-listbox',
      },
    })

    expect(view.getByRole('listbox')).toHaveAttribute('id', 'custom-listbox')
    const options = view.getAllByRole('option')
    expect(options[0]).toHaveAttribute('id', 'custom-listbox-option-0')
    expect(options[1]).toHaveAttribute('id', 'custom-listbox-option-1')
  })
})

describe('answers related to the edited record', () => {
  const relatedItem = (
    id: number,
    title: string,
    section: MentionKnowledgeBaseRelatedItem['section'],
  ): MentionKnowledgeBaseRelatedItem => ({
    id: convertToGraphQLId('KnowledgeBase::Answer::Translation', id),
    title,
    maybeLocale: null,
    categoryTreeTranslation: [
      {
        __typename: 'KnowledgeBaseCategoryTranslation',
        id: convertToGraphQLId('KnowledgeBase::Category::Translation', 1),
        title: 'Network',
      },
    ],
    section,
  })

  const items = [
    relatedItem(1, 'VPN setup on company notebooks (Windows)', 'linked'),
    relatedItem(2, 'VPN setup on company notebooks (macOS)', 'linked'),
    relatedItem(3, 'VPN troubleshooting', 'suggested'),
  ]

  const renderRelatedList = (props: { query?: string; items?: PossibleItem[] } = {}) => {
    const listExposed = ref<{ onKeyDown: (e: any) => void }>()
    const command = vi.fn()

    const view = renderComponent(
      {
        components: { FieldEditorSuggestionList },
        template: `<FieldEditorSuggestionList v-bind="$props" ref="listExposed" />`,
        setup: () => ({ listExposed }),
      },
      {
        props: {
          query: '',
          items,
          type: 'knowledge-base',
          command,
          ...baseProps,
          placeholder: 'Start typing to search in knowledge base…',
          ...props,
        },
      },
    )

    const triggerKey = async (key: string) => {
      listExposed.value?.onKeyDown({ event: { key } })
      await flushPromises()
    }

    return { view, command, triggerKey }
  }

  it('lists the linked answers first and the suggested ones second, below the search hint', () => {
    const { view } = renderRelatedList()

    expect(view.getByText('Start typing to search in knowledge base…')).toBeInTheDocument()

    const linked = view.getByRole('group', { name: 'Linked' })
    const suggested = view.getByRole('group', { name: 'Suggested knowledge' })

    expect(
      within(linked)
        .getAllByRole('option')
        .map((option) => option.textContent?.trim()),
    ).toEqual([
      expect.stringContaining('VPN setup on company notebooks (Windows)'),
      expect.stringContaining('VPN setup on company notebooks (macOS)'),
    ])
    expect(within(suggested).getByRole('option')).toHaveTextContent('VPN troubleshooting')

    expect(view.getAllByRole('option').map((option) => option.id)).toEqual([
      'mention-listbox-test-option-0',
      'mention-listbox-test-option-1',
      'mention-listbox-test-option-2',
    ])
  })

  it('shows the breadcrumb and, when handed over, the locale', () => {
    const { view } = renderRelatedList({
      items: [
        relatedItem(1, 'VPN setup on company notebooks (Windows)', 'linked'),
        { ...relatedItem(3, 'VPN troubleshooting', 'suggested'), maybeLocale: 'DE-DE' },
        relatedItem(4, 'VPN for contractors', 'suggested'),
      ],
    })

    expect(
      view.getByRole('option', { name: 'NetworkVPN setup on company notebooks (Windows)' }),
    ).toBeInTheDocument()
    expect(
      view.getByRole('option', { name: 'NetworkVPN troubleshooting (DE-DE)' }),
    ).toBeInTheDocument()
    expect(view.getByRole('option', { name: 'NetworkVPN for contractors' })).toBeInTheDocument()
  })

  it('keeps the sections while the first search term is still being searched for', () => {
    const { view } = renderRelatedList({ query: 'v' })

    expect(view.getByRole('group', { name: 'Linked' })).toBeInTheDocument()
    expect(view.getByRole('group', { name: 'Suggested knowledge' })).toBeInTheDocument()
  })

  it('leaves out a section without answers', () => {
    const { view } = renderRelatedList({
      items: [relatedItem(1, 'VPN setup on company notebooks (Windows)', 'linked')],
    })

    expect(view.getByRole('group', { name: 'Linked' })).toBeInTheDocument()
    expect(view.queryByRole('group', { name: 'Suggested knowledge' })).not.toBeInTheDocument()
  })

  it('shows only the search hint when there is nothing to offer', () => {
    const { view } = renderRelatedList({ items: [] })

    expect(view.getByText('Start typing to search in knowledge base…')).toBeInTheDocument()
    expect(view.queryByRole('group')).not.toBeInTheDocument()
    expect(view.queryByRole('option')).not.toBeInTheDocument()
  })

  it('moves across both sections with the arrow keys, skipping the headers', async () => {
    const { view, command, triggerKey } = renderRelatedList()

    const options = view.getAllByRole('option')

    expect(options[0]).toHaveAttribute('aria-selected', 'true')

    await triggerKey('ArrowDown')
    await triggerKey('ArrowDown')

    expect(options[2]).toHaveAttribute('aria-selected', 'true')

    await triggerKey('Enter')

    expect(command).toHaveBeenCalledWith(items[2])
  })

  it('inserts the clicked answer, the first one included', async () => {
    const { view, command, triggerKey } = renderRelatedList()

    await triggerKey('ArrowDown')
    await view.events.click(view.getAllByRole('option')[0])

    expect(command).toHaveBeenCalledWith(items[0])
  })
})
