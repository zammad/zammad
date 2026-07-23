// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { useKnowledgeBaseAccess } from '../composables/useKnowledgeBaseAccess.ts'

describe('useKnowledgeBaseAccess', () => {
  describe('canBrowse', () => {
    it('allows browsing when a knowledge base is publicly available', () => {
      mockApplicationConfig({ kb_active_publicly: true, kb_active: false })
      mockPermissions([])

      expect(useKnowledgeBaseAccess().canBrowse.value).toBe(true)
    })

    it('allows browsing an internal knowledge base with the knowledge base permission', () => {
      mockApplicationConfig({ kb_active_publicly: false, kb_active: true })
      mockPermissions(['knowledge_base.reader'])

      expect(useKnowledgeBaseAccess().canBrowse.value).toBe(true)
    })

    it('denies browsing an internal knowledge base without the permission', () => {
      mockApplicationConfig({ kb_active_publicly: false, kb_active: true })
      mockPermissions(['ticket.agent'])

      expect(useKnowledgeBaseAccess().canBrowse.value).toBe(false)
    })

    it('denies browsing when no knowledge base is active', () => {
      mockApplicationConfig({ kb_active_publicly: false, kb_active: false })
      mockPermissions(['knowledge_base.editor'])

      expect(useKnowledgeBaseAccess().canBrowse.value).toBe(false)
    })
  })

  describe('canEdit', () => {
    it('is true for a knowledge base editor', () => {
      mockPermissions(['knowledge_base.editor'])

      expect(useKnowledgeBaseAccess().canEdit.value).toBe(true)
    })

    it('is false without the editor permission', () => {
      mockPermissions(['knowledge_base.reader'])

      expect(useKnowledgeBaseAccess().canEdit.value).toBe(false)
    })
  })
})
