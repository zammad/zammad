// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  type ExtendedRenderResult,
  renderComponent,
} from '#tests/support/components/index.ts'

import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'

import { mockDetailViewSetup } from '#desktop/pages/ticket/components/TicketDetailView/__tests__/support/article-detail-view-mocks.ts'
import { modules as articleTypeModules } from '#desktop/pages/ticket/components/TicketDetailView/article-type/index.ts'
import type { ArticleTypeName } from '#desktop/pages/ticket/components/TicketDetailView/article-type/types.ts'
import ArticleBubbleMetaFields from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleMetaFields.vue'

const hasBaseInformation = (wrapper: ExtendedRenderResult) => {
  expect(wrapper.getByText('Created at')).toBeInTheDocument()
  expect(wrapper.getByText('2011-12-11 11:11')).toBeInTheDocument()

  expect(wrapper.getByText('From')).toBeInTheDocument()
  expect(wrapper.getByText('Nicole Braun')).toBeInTheDocument()
  expect(wrapper.getByText(/nicole.braun@zammad.org/i)).toBeInTheDocument()
}

const renderWrapper = (
  articleType: ArticleTypeName,
  options?: { articleData?: Parameters<typeof createDummyArticle>[0] },
) => {
  return renderComponent(
    {
      setup() {
        const { article } = mockDetailViewSetup({
          article: {
            articleType,
            ...options?.articleData,
          },
        })
        return { article }
      },
      components: { ArticleBubbleMetaFields },
      template: `<div><ArticleBubbleMetaFields :article="article" /></div>>`,
    },
    { router: true },
  )
}

describe('ArticleBubbleMetaFields', () => {
  it.each(articleTypeModules)(
    'displays meta field for channel $name',
    ({ name, icon }) => {
      const wrapper = renderWrapper(name as ArticleTypeName)

      hasBaseInformation(wrapper)

      expect(wrapper.getByText('Channel')).toBeInTheDocument()
      expect(wrapper.getByText(name)).toBeInTheDocument()
      expect(wrapper.getByIconName(icon)).toBeInTheDocument()
    },
  )

  describe('hidden features', () => {
    it('displays links on channel field if available', () => {
      const wrapper = renderWrapper('web', {
        articleData: {
          preferences: {
            links: [
              {
                label: 'Zammad',
                api: true,
                url: '/zammad.org',
                target: '_blank',
              },
              {
                label: 'Vue',
                api: true,
                url: '/vuejs.org/',
                target: '_blank',
              },
            ],
          },
        },
      })

      expect(wrapper.getByRole('link', { name: 'Zammad' })).toBeInTheDocument()
      expect(wrapper.getByRole('link', { name: 'Vue' })).toBeInTheDocument()

      expect(wrapper.getByRole('link', { name: 'Zammad' })).toHaveAttribute(
        'href',
        '/api/zammad.org',
      )
      expect(wrapper.getByRole('link', { name: 'Vue' })).toHaveAttribute(
        'href',
        '/api/vuejs.org/',
      )
    })
  })
})
