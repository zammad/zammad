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

  // Every plugin gets a detailed-search tab, so every plugin must be renderable - or SearchContent
  //   has nothing to put in the tab panel it just created. `detailSearchComponent` and
  //   `detailSearchHeaders` are optional on SearchPlugin, so nothing but this asserts it.
  it('leaves every plugin with a table to render', () => {
    mockPermissions(['ticket.agent', 'admin.user', 'admin.organization', 'knowledge_base.reader'])
    mockApplicationConfig({ kb_active: true })

    const { plugins } = useSearchPlugins()

    expect(
      plugins.value.every((plugin) => plugin.detailSearchComponent && plugin.detailSearchHeaders),
    ).toBe(true)
  })
})
