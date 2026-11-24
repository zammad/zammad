// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { nextTick, ref } from 'vue'

import { queryByIconName } from '#tests/support/components/iconQueries.ts'
import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { EXTENSION_NAME as TEXT_TOOL_EXTENSION_NAME } from '#shared/components/Form/fields/FieldEditor/extensions/AiAssistantTextTools.ts'
import type { FieldEditorNotice } from '#shared/components/Form/fields/FieldEditor/types.ts'
import {
  getEditorComponents,
  initializeEditorComponents,
} from '#shared/components/Form/initializeFieldEditor.ts'
import { i18n } from '#shared/i18n.ts'
import getUuid from '#shared/utils/getUuid.ts'

import FieldEditorActionMenu from '#desktop/components/Form/fields/FieldEditor/FieldEditorActionMenu.vue'
import { FIELD_EDITOR_OPTIONS } from '#desktop/components/Form/fields/FieldEditor/useFieldEditorOptions.ts'

import FieldEditorActionBar from '../FieldEditorActionBar.vue'
// not actually executed in a unit test, should speed up tests
vi.mock('@tiptap/vue-3', () => {
  return {
    VueRenderer: () => true,
  }
})

vi.mock('@tiptap/pm/state', () => {
  return {
    PluginKey: class {},
  }
})

describe('keyboard interactions', () => {
  it('can use arrows to traverse toolbar', async () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        visible: true,
        contentType: 'text/html',
        disabledExtensions: [],
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
        disabledExtensions: [],
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

  it.todo('hides on blur', async () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/html',
        visible: true,
        disabledExtensions: [],
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
        disabledExtensions: [],
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
        disabledExtensions: [],
        formId: getUuid(),
      },
    })

    await view.events.click(document.body)

    expect(view.emitted().hide).toBeTruthy()
  })
})

describe('basic toolbar testing', () => {
  it("don't see disabled actions", () => {
    mockPermissions(['ticket.agent'])

    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/html',
        visible: true,
        disabledExtensions: ['mentionUser'],
        formId: getUuid(),
      },
    })

    expect(view.queryByRole('button', { name: 'Mention user' })).not.toBeInTheDocument()
    expect(view.queryByLabelText('Mention user')).not.toBeInTheDocument()
    expect(view.queryByText('Mention user')).not.toBeInTheDocument()
    expect(view.queryByIconName('at-sign')).not.toBeInTheDocument()
  })

  it('see an action which is not disabled', () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/html',
        visible: true,
        disabledExtensions: [],
        formId: getUuid(),
      },
    })

    expect(view.getByLabelText('Remove formatting')).toBeInTheDocument()
  })

  it('see the answer link tool when the field opts into it', () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/html',
        visible: true,
        disabledExtensions: [],
        formId: getUuid(),
      },
    })

    expect(view.getByLabelText('Link answer')).toBeInTheDocument()
  })

  it('see the answer link tool without a dropdown caret', () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/html',
        visible: true,
        disabledExtensions: [],
        formId: getUuid(),
      },
    })

    // It opens the link form next to the caret, like the plain link tool, not a toolbar dropdown.
    expect(queryByIconName(view.getByLabelText('Link answer'), 'chevron-down')).toBeNull()
  })

  it('see the video embed tool when the field opts into it', () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/html',
        visible: true,
        disabledExtensions: [],
        formId: getUuid(),
      },
    })

    expect(view.getByLabelText('Embed video')).toBeInTheDocument()
  })

  it('see the video embed tool without a dropdown caret', () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/html',
        visible: true,
        disabledExtensions: [],
        formId: getUuid(),
      },
    })

    // It opens its form next to the caret, like the link tools, not a toolbar dropdown.
    expect(queryByIconName(view.getByLabelText('Embed video'), 'chevron-down')).toBeNull()
  })

  it("don't see the video embed tool when the field does not opt into it", () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/html',
        visible: true,
        disabledExtensions: ['videoEmbed'],
        formId: getUuid(),
      },
    })

    expect(view.queryByLabelText('Embed video')).not.toBeInTheDocument()
  })

  it("don't see the answer link tool when the field does not opt into it", () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/html',
        visible: true,
        disabledExtensions: ['knowledgeBaseAnswerLink'],
        formId: getUuid(),
      },
    })

    expect(view.queryByLabelText('Link answer')).not.toBeInTheDocument()
  })

  it("don't see a disabled action which has no extension of its own", () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/html',
        visible: true,
        disabledExtensions: ['removeFormatting'],
        formId: getUuid(),
      },
    })

    expect(view.queryByLabelText('Remove formatting')).not.toBeInTheDocument()
  })

  it("don't see plain text actions", async () => {
    const view = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/plain',
        visible: true,
        disabledExtensions: [],
        formId: getUuid(),
      },
    })

    expect(view.queryByRole('button', { name: 'Mention user' })).not.toBeInTheDocument()
    expect(view.queryByLabelText('Mention user')).not.toBeInTheDocument()

    expect(view.queryByLabelText('Add link')).not.toBeInTheDocument()
    expect(view.queryByLabelText('Add image')).not.toBeInTheDocument()
    expect(view.queryByLabelText('Format as underlined')).not.toBeInTheDocument()
  })

  describe('AiAssistantTextTools', () => {
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
          disabledExtensions: [],
          formId: getUuid(),
        },
      })

      expect(
        wrapper.queryByRole('button', { name: 'AI writing assistant tools' }),
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
          disabledExtensions: [],
          formId: getUuid(),
        },
      })

      expect(
        wrapper.queryByRole('button', { name: 'AI writing assistant tools' }),
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
          disabledExtensions: [],
          formId: getUuid(),
        },
      })

      expect(
        wrapper.queryByRole('button', { name: 'AI writing assistant tools' }),
      ).not.toBeInTheDocument()
    })
  })

  it('allows injection of options', async () => {
    const wrapper = renderComponent(FieldEditorActionBar, {
      props: {
        contentType: 'text/html',
        visible: true,
        disabledExtensions: [],
        formId: getUuid(),
      },
      provide: [[FIELD_EDITOR_OPTIONS, { zIndex: '100' }]],
    })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Add heading' }))

    const popover = await wrapper.findByRole('region', {
      name: 'Add heading',
    })

    expect(popover).toHaveStyle('z-index: 100;')
  })
})

const renderActionBar = (notice?: FieldEditorNotice, editor?: unknown) =>
  renderComponent(FieldEditorActionBar, {
    props: {
      contentType: 'text/html',
      visible: true,
      disabledExtensions: [],
      formId: getUuid(),
      formContext: { notice },
      editor,
    },
  })

const editorStub = (storage: Record<string, unknown> = {}) => ({
  isActive: () => false,
  getAttributes: () => ({}),
  on: vi.fn(),
  off: vi.fn(),
  storage,
})

describe('notice', () => {
  it('shows the notice below the toolbar', () => {
    const view = renderActionBar({ key: 'first', text: 'Mind the gap.' })

    const notice = view.getByRole('alert')

    expect(notice).toHaveTextContent('Mind the gap.')
    expect(
      view.getByRole('toolbar').compareDocumentPosition(notice) & Node.DOCUMENT_POSITION_FOLLOWING,
    ).toBeTruthy()
  })

  it('fills the placeholders of the translated notice', () => {
    i18n.setTranslationMap(new Map([['Mind the %s.', 'Achte auf %s.']]))
    onTestFinished(() => i18n.setTranslationMap(new Map()))

    const view = renderActionBar({ key: 'first', text: 'Mind the %s.', textPlaceholder: ['gap'] })

    expect(view.getByRole('alert')).toHaveTextContent('Achte auf gap.')
  })

  it('lets the user dismiss the notice, and shows the next one again', async () => {
    const view = renderActionBar({ key: 'first', text: 'Mind the gap.' })

    await view.events.click(view.getByRole('button', { name: 'Dismiss alert' }))

    expect(view.queryByRole('alert')).not.toBeInTheDocument()

    // The same notice handed over again stays away.
    await view.rerender({ formContext: { notice: { key: 'first', text: 'Mind the gap.' } } })

    expect(view.queryByRole('alert')).not.toBeInTheDocument()

    await view.rerender({ formContext: { notice: { key: 'second', text: 'Mind the step.' } } })

    expect(view.getByRole('alert')).toHaveTextContent('Mind the step.')
  })

  it('keeps a dismissed notice away when it comes back after there was none', async () => {
    const view = renderActionBar({ key: 'first', text: 'Mind the gap.' })

    await view.events.click(view.getByRole('button', { name: 'Dismiss alert' }))

    await view.rerender({ formContext: { notice: undefined } })
    await view.rerender({ formContext: { notice: { key: 'first', text: 'Mind the gap.' } } })

    expect(view.queryByRole('alert')).not.toBeInTheDocument()

    await view.rerender({ formContext: { notice: { key: 'second', text: 'Mind the step.' } } })

    expect(view.getByRole('alert')).toHaveTextContent('Mind the step.')
  })

  it('shows a dismissed notice again when it comes back after another one', async () => {
    const view = renderActionBar({ key: 'first', text: 'Mind the gap.' })

    await view.events.click(view.getByRole('button', { name: 'Dismiss alert' }))

    await view.rerender({ formContext: { notice: { key: 'second', text: 'Mind the step.' } } })
    await view.rerender({ formContext: { notice: { key: 'first', text: 'Mind the gap.' } } })

    expect(view.getByRole('alert')).toHaveTextContent('Mind the gap.')
  })

  it('shows nothing without a notice', () => {
    const view = renderActionBar()

    expect(view.queryByRole('alert')).not.toBeInTheDocument()
  })

  it('keeps the notice while the AI writing assistant hides the toolbar', async () => {
    mockApplicationConfig({ ai_assistance_text_tools: false })

    const showAiTextLoader = ref(false)

    const view = renderActionBar(
      { key: 'first', text: 'Mind the gap.' },
      editorStub({ [TEXT_TOOL_EXTENSION_NAME]: { showAiTextLoader } }),
    )

    showAiTextLoader.value = true

    await waitFor(() => expect(view.getByRole('toolbar', { hidden: true })).not.toBeVisible())
    expect(view.getByRole('alert')).toBeVisible()
  })
})

// The overflow menu button is told by its icon, the tooltip that names it is not set up here.
describe('overflow menu', () => {
  const editorComponents = getEditorComponents()

  beforeAll(() => {
    initializeEditorComponents({ ...editorComponents, actionMenu: FieldEditorActionMenu })
  })

  afterAll(() => {
    initializeEditorComponents(editorComponents)
  })

  // The latest of the mocked observers that watches the element.
  const observerOf = (element: Element) => {
    const { calls, results } = vi.mocked(IntersectionObserver).mock

    const index = results.findLastIndex(({ value }) =>
      value.observe.mock.calls.some(([target]: [Element]) => target === element),
    )

    if (index === -1) throw new Error('The element is not observed.')

    return calls[index][0]
  }

  const report = (element: Element, isIntersecting: boolean) =>
    observerOf(element)(
      [{ target: element, isIntersecting } as unknown as IntersectionObserverEntry],
      {} as IntersectionObserver,
    )

  it('moves an action that does not fit into the overflow menu', async () => {
    const view = renderActionBar(undefined, editorStub())

    const insertTable = view.getByRole('button', { name: 'Insert table' })
    await waitFor(() => observerOf(insertTable))

    report(insertTable, false)

    await waitFor(() => expect(view.queryByIconName('three-dots-vertical')).toBeInTheDocument())
  })

  // The specification lets an observer deliver a report it queued before it was disconnected.
  it('ignores a report of an action that arrives after the toolbar went out of view', async () => {
    const view = renderActionBar(undefined, editorStub())

    const toolbar = view.getByRole('toolbar')
    const insertTable = view.getByRole('button', { name: 'Insert table' })
    await waitFor(() => observerOf(toolbar))
    await waitFor(() => observerOf(insertTable))

    report(toolbar, false)
    report(insertTable, false)
    await nextTick()

    expect(view.queryByIconName('three-dots-vertical')).not.toBeInTheDocument()
  })
})
