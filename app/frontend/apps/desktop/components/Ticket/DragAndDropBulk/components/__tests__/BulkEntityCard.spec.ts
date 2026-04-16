// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import { DragAndDropBulkEntityType } from '../../types.ts'
import BulkEntityCard, { type Props } from '../BulkEntityCard.vue'

describe('BulkEntityCard', () => {
  const renderCard = (props: Props) => renderComponent(BulkEntityCard, { props })

  it('renders the label text', () => {
    const wrapper = renderCard({
      label: 'Run macro',
      entityType: DragAndDropBulkEntityType.Macro,
    })
    expect(wrapper.getByText('Run macro')).toBeInTheDocument()
  })

  describe('macro entity type', () => {
    it('renders the play-circle icon', () => {
      const wrapper = renderCard({
        label: 'Run macro',
        entityType: DragAndDropBulkEntityType.Macro,
      })
      expect(wrapper.getByIconName('play-circle')).toBeInTheDocument()
    })

    it('does not render the go-inside-group section', () => {
      const wrapper = renderCard({
        label: 'Run macro',
        entityType: DragAndDropBulkEntityType.Macro,
      })
      expect(wrapper.queryByIconName('arrow-down-short')).not.toBeInTheDocument()
    })
  })

  describe('ticket entity type', () => {
    it('renders the people-fill icon when no entity is provided', () => {
      const wrapper = renderCard({
        label: 'Assign tickets',
        entityType: DragAndDropBulkEntityType.Group,
      })
      expect(wrapper.getByIconName('people-fill')).toBeInTheDocument()
    })

    it('renders the go-inside-group section when is a group', () => {
      const wrapper = renderCard({
        label: 'Assign tickets',
        entityType: DragAndDropBulkEntityType.Group,
      })
      expect(wrapper.getByIconName('arrow-down-short')).toBeInTheDocument()
    })

    it('renders parents label', () => {
      const wrapper = renderCard({
        label: 'Assign tickets',
        entityType: DragAndDropBulkEntityType.Group,
        parentLabel: `Development \u203A Scrum`,
      })
      expect(wrapper.getByText('Development \u203A Scrum')).toBeInTheDocument()
    })

    it('does not render the go-inside-group section when is not a group', () => {
      const wrapper = renderCard({
        label: 'Assign tickets',
        entityType: DragAndDropBulkEntityType.Macro,
      })
      expect(wrapper.queryByIconName('arrow-down-short')).not.toBeInTheDocument()
    })
  })

  describe('system card entity type: "Unassign owner"', () => {
    let wrapper: ReturnType<typeof renderCard>
    beforeEach(() => {
      wrapper = renderCard({
        label: 'Unassign owner',
        entityType: DragAndDropBulkEntityType.Owner,
        entityInternalId: 1,
      })
    })
    it('renders the person-x icon', () => {
      expect(wrapper.getByIconName('person-x')).toBeInTheDocument()
    })

    it('does not render the go-inside-group section', () => {
      expect(wrapper.queryByIconName('arrow-down-short')).not.toBeInTheDocument()
    })

    it('does display correct label', () => {
      expect(wrapper.getByText('Unassign owner')).toBeInTheDocument()
    })
  })
})
