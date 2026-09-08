// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createPinia, setActivePinia } from 'pinia'

import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { EnumSearchableModels } from '#shared/graphql/types.ts'

import { useSearchPlugins } from '../index.ts'

describe('useSearchPlugins', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  // The knowledge base answer plugin is the first one gated by `show` rather than by `permissions`,
  //   because `canBrowse` mixes a setting with a permission and a `permissions` list cannot say
  //   that. `show` was declared on SearchPlugin long before anything used it, so both branches are
  //   covered explicitly here.
  describe('the show gate', () => {
    it('offers a knowledge base gated plugin when the user may browse one', () => {
      mockPermissions(['ticket.agent', 'knowledge_base.reader'])
      mockApplicationConfig({ kb_active: true })

      const { searchPluginNames } = useSearchPlugins()

      expect(searchPluginNames.value).toContain(EnumSearchableModels.KnowledgeBaseAnswerTranslation)
    })

    it('offers it to a customer when the knowledge base is publicly available', () => {
      mockPermissions(['ticket.customer'])
      mockApplicationConfig({ kb_active: true, kb_active_publicly: true })

      const { searchPluginNames } = useSearchPlugins()

      expect(searchPluginNames.value).toContain(EnumSearchableModels.KnowledgeBaseAnswerTranslation)
    })

    it('withholds it when no knowledge base is enabled', () => {
      mockPermissions(['ticket.agent', 'knowledge_base.reader'])
      mockApplicationConfig({ kb_active: false, kb_active_publicly: false })

      const { searchPluginNames } = useSearchPlugins()

      expect(searchPluginNames.value).not.toContain(
        EnumSearchableModels.KnowledgeBaseAnswerTranslation,
      )
    })
  })

  // An entity whose quicksearch group ships before its detailed-search table does has to stay out
  //   of the tab list and out of the searchCounts query behind the tab counters, while remaining
  //   available to quicksearch.
  describe('detailSearchDisabled', () => {
    beforeEach(() => {
      mockPermissions(['ticket.agent', 'admin.user', 'admin.organization', 'knowledge_base.reader'])
      mockApplicationConfig({ kb_active: true })
    })

    it('keeps the entity out of the detail-search plugins', () => {
      const { detailSearchPluginNames } = useSearchPlugins()

      expect(detailSearchPluginNames.value).not.toContain(
        EnumSearchableModels.KnowledgeBaseAnswerTranslation,
      )
    })

    it('leaves the other entities in the detail-search plugins', () => {
      const { detailSearchPluginNames } = useSearchPlugins()

      expect(detailSearchPluginNames.value).toEqual(
        expect.arrayContaining([
          EnumSearchableModels.Ticket,
          EnumSearchableModels.User,
          EnumSearchableModels.Organization,
        ]),
      )
    })

    it('still offers the entity to quicksearch', () => {
      const { sortedByPriorityPlugins } = useSearchPlugins()

      expect(sortedByPriorityPlugins.value.map((plugin) => plugin.name)).toContain(
        EnumSearchableModels.KnowledgeBaseAnswerTranslation,
      )
    })

    // Every detail-search plugin must be renderable, or SearchContent has nothing to put in the
    //   tab panel it just created.
    it('leaves every detail-search plugin with a table to render', () => {
      const { detailSearchPlugins } = useSearchPlugins()

      expect(
        detailSearchPlugins.value.every(
          (plugin) => plugin.detailSearchComponent && plugin.detailSearchHeaders,
        ),
      ).toBe(true)
    })
  })
})
