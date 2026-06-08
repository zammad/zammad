// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import '#tests/graphql/builders/mocks.ts'

import { mockFormUpdaterQuery } from '#shared/components/Form/graphql/queries/formUpdater.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import DragAndDropBulkWrapper, { type Props } from '../DragAndDropBulkWrapper.vue'

const defaultProps: Props = {
  cursorPosition: { x: 100, y: 100 },
  dropSuccessTargetEntity: null,
}

describe('DragAndDropBulkWrapper', () => {
  // CommonOverlayContainer teleports its backdrop to #app when fullscreen=true.
  let appDiv: HTMLDivElement

  beforeAll(() => {
    appDiv = document.createElement('div')
    appDiv.id = 'app'
    document.body.appendChild(appDiv)

    mockFormUpdaterQuery({
      formUpdater: {
        fields: {
          group_id: { options: [] },
          owner_id: {
            options: [
              { value: 42, label: 'John Doe', object: { id: convertToGraphQLId('User', '42') } },
            ],
          },
        },
      },
    })
  })

  afterAll(() => {
    document.body.removeChild(appDiv)
  })

  const renderWrapper = (props: Partial<Props> = {}) => {
    return renderComponent(DragAndDropBulkWrapper, {
      props: { ...defaultProps, ...props },
      router: true,
      store: true,
    })
  }

  it('does not show the confirmation dialog', () => {
    const wrapper = renderWrapper()
    expect(wrapper.queryByRole('dialog')).not.toBeInTheDocument()
  })
})
