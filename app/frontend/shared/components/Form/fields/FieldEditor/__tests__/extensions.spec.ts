// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  getDisabledExtensionNames,
  optInExtensionNames,
} from '#shared/components/Form/fields/FieldEditor/extensions.ts'

describe('getDisabledExtensionNames', () => {
  describe('opt-in tools', () => {
    it('switches an opt-in tool off when the field does not mention it', () => {
      expect(getDisabledExtensionNames({})).toContain('knowledgeBaseAnswerLink')
      expect(getDisabledExtensionNames(undefined)).toContain('knowledgeBaseAnswerLink')
    })

    it('switches an opt-in tool on when the field declares its key', () => {
      expect(getDisabledExtensionNames({ knowledgeBaseAnswerLink: {} })).not.toContain(
        'knowledgeBaseAnswerLink',
      )
    })

    it('switches an opt-in tool off again when its key carries disabled', () => {
      expect(getDisabledExtensionNames({ knowledgeBaseAnswerLink: { disabled: true } })).toContain(
        'knowledgeBaseAnswerLink',
      )
    })

    it('leaves the remaining opt-in tools off when one of them is opted into', () => {
      expect(getDisabledExtensionNames({ knowledgeBaseAnswerLink: {} })).toContain('videoEmbed')
    })

    it('switches every opt-in tool off in the basic set, even when opted into', () => {
      const disabled = getDisabledExtensionNames(
        { knowledgeBaseAnswerLink: {}, videoEmbed: {} },
        'basic',
      )

      expect(disabled).toEqual(expect.arrayContaining([...optInExtensionNames]))
    })

    it('lists a name that is both opted out and disabled only once', () => {
      const disabled = getDisabledExtensionNames({ videoEmbed: { disabled: true } }, 'basic')

      expect(disabled.filter((name) => name === 'videoEmbed')).toHaveLength(1)
    })
  })

  describe('regular tools', () => {
    it('leaves a tool on when the field does not mention it', () => {
      expect(getDisabledExtensionNames({})).not.toContain('mentionUser')
    })

    it('leaves a tool on when its key carries no disabled flag', () => {
      expect(
        getDisabledExtensionNames({ mentionUser: { groupNodeName: 'group_id' } }),
      ).not.toContain('mentionUser')
    })

    it('switches a tool off when its key carries disabled', () => {
      expect(getDisabledExtensionNames({ mentionUser: { disabled: true } })).toContain(
        'mentionUser',
      )
    })

    it('leaves a tool on in the basic set, which is handled by the extension list instead', () => {
      expect(getDisabledExtensionNames({}, 'basic')).not.toContain('mentionUser')
    })
  })
})
