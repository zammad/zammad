// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'
import { ref } from 'vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { mockAiAssistanceTextToolsRunMutation } from '#shared/graphql/mutations/aiAssistanceTextToolsRun.mocks.ts'
import { useAiAssistantTextToolsStore } from '#shared/stores/aiAssistantTextTools.ts'
import getUuid from '#shared/utils/getUuid.ts'

import FieldEditorActionBar from '../FieldEditorActionBar.vue'

// not actually executed in a unit test, should speed up tests
vi.mock('@tiptap/vue-3', () => {
  return {
    VueRenderer: () => true,
  }
})

vi.mock('@tiptap/pm/state', () => {
  return {
    PluginKey: vi.fn((name: string) => name),
  }
})

vi.mock('prosemirror-model', () => {
  return {
    DOMSerializer: {
      fromSchema: vi.fn(() => ({
        serializeFragment: vi.fn(() => {
          const fragment = document.createDocumentFragment()
          fragment.textContent = 'selected text'
          return fragment
        }),
      })),
    },
  }
})

describe('keyboard interactions', () => {
  it('can use arrows to traverse toolbar', async () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        visible: true,
        contentType: 'text/html',
        disabledPlugins: [],
        formId: getUuid(),
      },
    })

    const actions = view.getAllByRole('button')

    await view.events.click(view.getByRole('toolbar'))

    await view.events.keyboard('{ArrowRight}')
    expect(actions[0]).toHaveFocus()

    await view.events.keyboard('{ArrowRight}')
    expect(actions[1]).toHaveFocus()

    await view.events.keyboard('{ArrowLeft}')
    expect(actions[0]).toHaveFocus()

    await view.events.keyboard('{ArrowLeft}')
    expect(actions.at(-1)).toHaveFocus()

    await view.events.keyboard('{ArrowRight}')
    expect(actions[0]).toHaveFocus()
  })

  it('can use home and end to traverse toolbar', async () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        visible: true,
        contentType: 'text/html',
        disabledPlugins: [],
        formId: getUuid(),
      },
    })

    const actions = view.getAllByRole('button')

    await view.events.click(view.getByRole('toolbar'))

    await view.events.keyboard('{Home}')
    expect(actions[0]).toHaveFocus()

    await view.events.keyboard('{End}')
    expect(actions.at(-1)).toHaveFocus()
  })

  it('hides on blur', async () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/html',
        visible: true,
        disabledPlugins: [],
        formId: getUuid(),
      },
    })

    await view.events.click(view.getByRole('toolbar'))
    await view.events.keyboard('{Tab}')

    expect(view.emitted().hide).toBeTruthy()
  })

  it('hides on escape', async () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/html',
        visible: true,
        disabledPlugins: [],
        formId: getUuid(),
      },
    })

    await view.events.click(view.getByRole('toolbar'))
    await view.events.keyboard('{Escape}')

    // emits blur, because toolbar is not hidden, but focus is shifted to the editor instead
    expect(view.emitted().blur).toBeTruthy()
  })

  it('hides on click outside', async () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/html',
        visible: true,
        disabledPlugins: [],
        formId: getUuid(),
      },
    })

    await view.events.click(document.body)

    expect(view.emitted().hide).toBeTruthy()
  })
})

describe('basic toolbar testing', () => {
  it("don't see disabled actions", () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/html',
        visible: true,
        disabledPlugins: ['mentionUser'],
        formId: getUuid(),
      },
    })

    expect(view.queryByRole('button', { name: 'Mention user' })).not.toBeInTheDocument()
    expect(view.queryByLabelText('Mention user')).not.toBeInTheDocument()
    expect(view.queryByText('Mention user')).not.toBeInTheDocument()
    expect(view.queryByIconName('at-sign')).not.toBeInTheDocument()
  })

  it("don't see plain text actions", async () => {
    mockPermissions(['ticket.agent'])
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/plain',
        visible: true,
        disabledPlugins: [],
        formId: getUuid(),
      },
    })

    expect(view.getByLabelText('Insert text from text module')).toBeInTheDocument()

    expect(view.getByIconName('text-modules')).toBeInTheDocument()

    expect(view.getByLabelText('Insert text from knowledge base answer')).toBeInTheDocument()
    expect(view.getByIconName('book')).toBeInTheDocument()

    expect(view.queryByRole('button', { name: 'Mention user' })).not.toBeInTheDocument()
    expect(view.queryByLabelText('Mention user')).not.toBeInTheDocument()

    expect(view.queryByLabelText('Add link')).not.toBeInTheDocument()
    expect(view.queryByLabelText('Add image')).not.toBeInTheDocument()
    expect(view.queryByLabelText('Format as underlined')).not.toBeInTheDocument()
  })

  describe('AiAssistantTextTools', () => {
    const modifyTextWithAi = vi.fn()
    const createMockEditor = () => ({
      state: {
        selection: {
          from: 0,
          to: 10,
          anchor: 0,
          head: 10,
          empty: false,
          content: () => 'selected text',
        },
        doc: {
          textBetween: vi.fn(() => 'selected text'),
        },
      },
      chain: vi.fn(() => ({
        focus: vi.fn(() => ({
          setTextSelection: vi.fn(() => ({
            run: vi.fn(),
          })),
        })),
      })),
      isActive: vi.fn(() => true),
      getAttributes: vi.fn(() => ({})),
      isFocused: false,
      commands: {
        deleteSelection: vi.fn(),
        insertContentAt: vi.fn(),
        focus: vi.fn(),
        setTextSelection: vi.fn(),
        modifyTextWithAi,
      },
      setEditable: vi.fn(),
      on: vi.fn(),
      off: vi.fn(),
      emit: vi.fn(),
    })

    it('hides feature if flag is not set', async () => {
      mockApplicationConfig({
        ai_assistance_text_tools: false,
        ai_provider: true,
      })

      mockPermissions(['ticket.agent'])

      const wrapper = renderComponent(FieldEditorActionBar, {
        props: {
          contentType: 'text/plain',
          visible: true,
          disabledPlugins: [],
          formId: getUuid(),
        },
      })

      expect(
        wrapper.queryByRole('button', { name: 'Writing Assistant Tools' }),
      ).not.toBeInTheDocument()
    })

    it('hides the feature if user is customer', async () => {
      mockApplicationConfig({
        ai_assistance_text_tools: true,
        ai_provider: true,
      })

      mockPermissions(['ticket.customer'])

      const wrapper = renderComponent(FieldEditorActionBar, {
        props: {
          contentType: 'text/plain',
          visible: true,
          disabledPlugins: [],
          formId: getUuid(),
        },
      })

      expect(
        wrapper.queryByRole('button', { name: 'Writing Assistant Tools' }),
      ).not.toBeInTheDocument()
    })

    it('hides the feature if user ai provider is not set', async () => {
      mockApplicationConfig({
        ai_assistance_text_tools: true,
        ai_provider: undefined,
      })

      mockPermissions(['ticket.customer'])

      const wrapper = renderComponent(FieldEditorActionBar, {
        props: {
          contentType: 'text/plain',
          visible: true,
          disabledPlugins: [],
          formId: getUuid(),
        },
      })

      expect(
        wrapper.queryByRole('button', { name: 'AI writing assistant tools' }),
      ).not.toBeInTheDocument()
    })

    it('can use custom text tools', async () => {
      mockApplicationConfig({
        ai_assistance_text_tools: true,
        ai_provider: true,
      })

      mockPermissions(['ticket.agent'])

      mockAiAssistanceTextToolsRunMutation({
        aiAssistanceTextToolsRun: {
          output: 'selected text',
        },
      })

      const mockEditor = createMockEditor()

      const formId = getUuid()

      // Mock the store's lookupResult to return our test data
      // Mock query would be cleaner, but makes troubles
      const store = useAiAssistantTextToolsStore()

      vi.spyOn(store, 'lookupResult').mockReturnValue(
        ref({
          aiAssistanceTextToolsList: [
            {
              id: 'expand-tool-123',
              name: 'Expand',
              active: true,
            },
          ],
        }),
      )

      const wrapper = renderComponent(FieldEditorActionBar, {
        props: {
          contentType: 'text/plain',
          visible: true,
          disabledPlugins: [],
          formId,
          editor: mockEditor,
          formContext: {
            formId,
            node: {
              value: null,
            },
          },
        },
      })

      const button = await wrapper.findByRole('button', { name: 'AI writing assistant tools' })
      await wrapper.events.click(button)

      const sectionMenu = await wrapper.findByRole('alert')

      await wrapper.events.click(within(sectionMenu).getByRole('button', { name: 'Expand' }))

      expect(modifyTextWithAi).toHaveBeenCalledWith('expand-tool-123')
    })
  })
})
