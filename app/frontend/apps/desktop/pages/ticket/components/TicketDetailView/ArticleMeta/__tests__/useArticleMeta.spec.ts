// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { createDummyArticle } from '#shared/entities/ticket-article/__tests__/mocks/ticket-articles.ts'

import { useArticleMeta } from '#desktop/pages/ticket/components/TicketDetailView/ArticleMeta/useArticleMeta.ts'

const CommonDateTimeMock = {
  __file: '#shared/components/CommonDateTime/CommonDateTime.vue',
  __name: 'CommonDateTime',
  props: {
    absoluteFormat: {
      default: 'datetime',
      required: false,
      type: String,
    },
    dateTime: {
      required: true,
      type: String,
    },
    type: {
      default: 'configured',
      required: false,
      type: String,
    },
  },
  render: vi.fn(),
  setup: vi.fn(),
}

const ArticleMetaAddressMock = {
  __file:
    '#desktop/pages/ticket/components/TicketDetailView/ArticleMeta/ArticleMetaAddress.vue',
  __name: 'ArticleMetaAddress',
  props: {
    context: {
      required: true,
      type: Object,
    },
    type: {
      default: 'from',
      required: false,
      type: String,
    },
  },
  render: vi.fn(),
  setup: vi.fn(),
}

vi.mock(
  '#desktop/pages/ticket/components/TicketDetailView/ArticleMeta/useArticleMeta.ts',
  () => ({
    useArticleMeta: () => ({
      fields: ref([
        {
          component: CommonDateTimeMock,
          label: 'Created at',
          name: 'created_at',
          order: 100,
          props: {
            class: 'text-sm',
            dateTime: '2011-12-11T11:11:11.011Z',
            type: 'absolute',
          },
        },
        {
          component: ArticleMetaAddressMock,
          label: 'From',
          name: 'from',
          order: 200,
          props: {
            type: 'from',
          },
          show: vi.fn(),
        },
        {
          component: undefined,
          icon: undefined,
          label: 'Channel',
          name: 'channel',
          order: 400,
          value: undefined,
        },
      ]),
    }),
  }),
)

const expectedArray = [
  {
    component: CommonDateTimeMock,
    label: 'Created at',
    name: 'created_at',
    order: 100,
    props: {
      class: 'text-sm',
      dateTime: '2011-12-11T11:11:11.011Z',
      type: 'absolute',
    },
  },
  {
    component: ArticleMetaAddressMock,
    label: 'From',
    name: 'from',
    order: 200,
    props: {
      type: 'from',
    },
    show: expect.any(Function),
  },
  {
    component: undefined,
    icon: undefined,
    label: 'Channel',
    name: 'channel',
    order: 400,
    value: undefined,
  },
]

describe('useArticleMeta', () => {
  it('returns an array of meta fields', () => {
    const { fields } = useArticleMeta(
      ref(createDummyArticle({ articleType: 'phone' }) as TicketArticle),
    )

    expect(fields.value).toEqual(expectedArray)
  })
})
