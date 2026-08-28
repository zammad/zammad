// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { getDisabledExtensionNames } from '#shared/components/Form/fields/FieldEditor/extensions.ts'
import type { FieldEditorProps } from '#shared/components/Form/fields/FieldEditor/types.ts'
import getUuid from '#shared/utils/getUuid.ts'

import FieldEditorActionBar from '#desktop/components/Form/fields/FieldEditor/FieldEditorActionBar.vue'
import { ANSWER_EDITOR_TOOLS } from '#desktop/entities/knowledge-base/utils/answerEditorTools.ts'

// The tools an answer is not written with, being a ticket article's. Each is gated by a permission
//   or a setting of its own, which the test grants: a tool has to be missing because the answer
//   form says so, and not because nothing would have shown it in the first place.
const TICKET_TOOLS = [
  'AI writing assistant tools',
  'Mention user',
  'Insert text from knowledge base answer',
  'Insert text from text module',
]

const KNOWLEDGE_BASE_TOOLS = ['Link answer', 'Embed video']

// Cross-checked against the buttons the legacy answer editor offered
//   (`app/assets/javascripts/app/models/knowledge_base_answer.coffee`): nothing it had may be
//   missing, and what the new toolbar has on top of it stays.
const EVERYDAY_TOOLS = ['Add link', 'Add image', 'Format as bold', 'Insert table']

// The toolbar the answer's body field gets, which is the visible half of what its `meta` declares;
//   the editor itself is mocked away in this environment, so the tools are asked of the toolbar.
const renderToolbar = (meta: FieldEditorProps['meta']) =>
  renderComponent(FieldEditorActionBar, {
    props: {
      contentType: 'text/html',
      visible: true,
      disabledExtensions: getDisabledExtensionNames(meta),
      formId: getUuid(),
    },
  })

describe('the editor tools a knowledge base answer is written with', () => {
  beforeEach(() => {
    mockPermissions(['ticket.agent'])
    mockApplicationConfig({ ai_assistance_text_tools: true, ai_provider: true })
  })

  it('leaves out the tools of a ticket article', () => {
    const view = renderToolbar(ANSWER_EDITOR_TOOLS)

    TICKET_TOOLS.forEach((tool) => {
      expect(view.queryByLabelText(tool), tool).not.toBeInTheDocument()
    })
  })

  it('offers both knowledge base tools', () => {
    const view = renderToolbar(ANSWER_EDITOR_TOOLS)

    // Off in every other editor, and switched on by the answer form naming them.
    KNOWLEDGE_BASE_TOOLS.forEach((tool) => {
      expect(view.getByLabelText(tool), tool).toBeInTheDocument()
    })
  })

  it('keeps everything else an answer is written with', () => {
    const view = renderToolbar(ANSWER_EDITOR_TOOLS)

    EVERYDAY_TOOLS.forEach((tool) => {
      expect(view.getByLabelText(tool), tool).toBeInTheDocument()
    })
  })

  it('is what decides which of them there are', () => {
    // The same toolbar for a field that declares nothing, so that the tests above cannot pass on a
    //   toolbar that never had those tools to begin with.
    const view = renderToolbar({})

    TICKET_TOOLS.forEach((tool) => {
      expect(view.getByLabelText(tool), tool).toBeInTheDocument()
    })

    KNOWLEDGE_BASE_TOOLS.forEach((tool) => {
      expect(view.queryByLabelText(tool), tool).not.toBeInTheDocument()
    })
  })
})
