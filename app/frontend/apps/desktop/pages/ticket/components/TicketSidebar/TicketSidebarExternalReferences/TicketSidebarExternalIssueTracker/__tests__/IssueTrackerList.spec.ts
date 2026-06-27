// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { within } from '@testing-library/vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import {
  EnumTicketExternalReferencesIssueTrackerItemState,
  EnumTicketExternalReferencesIssueTrackerType,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import IssueTrackerList from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarExternalIssueTracker/IssueTrackerList.vue'
import { mockTicketExternalReferencesIssueTrackerItemListQuery } from '#desktop/pages/ticket/graphql/queries/ticketExternalReferencesIssueTrackerList.mocks.ts'
import { TicketSidebarScreenType } from '#desktop/pages/ticket/types/sidebar.ts'

const mockedIssues = [
  {
    assignees: ['Benjamin Foo'],
    issueId: 356,
    issueType: { name: 'Story', color: 'PURPLE' },
    labels: [
      {
        color: '#009966',
        textColor: '#FFFFFF',
        title: 'New tech stack',
      },
    ],
    milestone: 'Frontend refactoring',
    state: EnumTicketExternalReferencesIssueTrackerItemState.Open,
    title: 'Example issue for GitHub integration',
    url: 'https://github.com/zammad/zammad/issues/123',
  },
]

describe('IssueTrackerWrapper', () => {
  it('renders GitHub issues correctly including issue type', async () => {
    mockTicketExternalReferencesIssueTrackerItemListQuery({
      ticketExternalReferencesIssueTrackerItemList: mockedIssues,
    })

    const wrapper = renderComponent(IssueTrackerList, {
      props: {
        screenType: TicketSidebarScreenType.TicketDetailView,
        isTicketEditable: true,
        trackerType: EnumTicketExternalReferencesIssueTrackerType.Github,
        flyoutConfig: {
          name: 'link-github-issue',
          icon: 'github',
          label: __('GitHub: Link issue'),
          inputPlaceholder: 'https://github.com/organization/repository/issues/42',
        },
        issueLinks: ['https://github.com/zammad/zammad/issues/356'],
        form: {},
        ticketId: convertToGraphQLId('Ticket', '1'),
      },
      router: true,
    })

    const link = await wrapper.findByRole('link', {
      name: '#356 Example issue for GitHub integration',
    })

    expect(link).toHaveTextContent('#356 Example issue for GitHub integration')
    expect(link).toHaveAttribute('href', 'https://github.com/zammad/zammad/issues/123')

    expect(wrapper.getByText('Type')).toBeInTheDocument()
    const issueTypeBadge = wrapper.getByText('Story')
    expect(issueTypeBadge).toBeInTheDocument()
    expect(issueTypeBadge).toHaveStyle('background-color: #8250DF') // PURPLE light-mode
    expect(issueTypeBadge).toHaveStyle('color: #FFFFFF')

    expect(wrapper.getByText('Assignee')).toBeInTheDocument()
    expect(wrapper.getByText('Benjamin Foo')).toBeInTheDocument()

    expect(wrapper.getByText('Milestone')).toBeInTheDocument()
    expect(wrapper.getByText('Frontend refactoring')).toBeInTheDocument()

    expect(wrapper.getByText('Labels')).toBeInTheDocument()

    const issueLabelList = wrapper.getByRole('list', {
      name: 'List of issue labels',
    })

    const item = within(issueLabelList).getByRole('listitem')

    expect(item).toHaveStyle('background-color: #009966')
    expect(item).toHaveStyle('color: #FFFFFF')
    expect(item).toHaveTextContent('New tech stack')
  })

  it('renders GitLab issues correctly without issue type', async () => {
    mockTicketExternalReferencesIssueTrackerItemListQuery({
      ticketExternalReferencesIssueTrackerItemList: [{ ...mockedIssues[0], issueType: null }],
    })

    const wrapper = renderComponent(IssueTrackerList, {
      props: {
        screenType: TicketSidebarScreenType.TicketDetailView,
        isTicketEditable: true,
        trackerType: EnumTicketExternalReferencesIssueTrackerType.Gitlab,
        flyoutConfig: {
          name: 'link-gitlab-issue',
          icon: 'gitlab',
          label: __('GitLab: Link issue'),
          inputPlaceholder: 'https://git.example.com/group1/project1/-/issues/1',
        },
        issueLinks: ['https://git.zammad.com/zammad/zammad/-/issues/356'],
        form: {},
        ticketId: convertToGraphQLId('Ticket', '1'),
      },
      router: true,
    })

    await wrapper.findByRole('link', { name: '#356 Example issue for GitHub integration' })

    expect(wrapper.queryByText('Type')).not.toBeInTheDocument()
  })

  it('separates assignees with comma if there are multiple', async () => {
    mockTicketExternalReferencesIssueTrackerItemListQuery({
      ticketExternalReferencesIssueTrackerItemList: [
        { ...mockedIssues, assignees: ['Benjamin Foo', 'Dominik Ha'] },
      ],
    })

    const wrapper = renderComponent(IssueTrackerList, {
      props: {
        screenType: TicketSidebarScreenType.TicketDetailView,
        trackerType: EnumTicketExternalReferencesIssueTrackerType.Gitlab,
        ticketTrackerTypeField: 'gitLabLinks',
        isTicketEditable: true,
        issueLinks: [],
        flyoutConfig: {
          name: 'link-gitlab-issue',
          icon: 'gitlab',
          label: __('GitLab: Link issue'),
          inputPlaceholder: 'https://git.example.com/group1/project1/-/issues/1',
        },
        ticketId: convertToGraphQLId('Ticket', '1'),
      },
      router: true,
    })

    expect(await wrapper.findByText('Assignees')).toBeInTheDocument()
    expect(wrapper.getByText('Benjamin Foo,')).toBeInTheDocument()
    expect(wrapper.getByText('Dominik Ha')).toBeInTheDocument()
  })

  it('renders issue on ticket create setup.', async () => {
    mockTicketExternalReferencesIssueTrackerItemListQuery({
      ticketExternalReferencesIssueTrackerItemList: mockedIssues,
    })
    const wrapper = renderComponent(IssueTrackerList, {
      props: {
        screenType: TicketSidebarScreenType.TicketCreate,
        trackerType: EnumTicketExternalReferencesIssueTrackerType.Gitlab,
        isTicketEditable: true,
        issueLinks: ['https://git.zammad.com/zammad/zammad/-/issues/356'],
        flyoutConfig: {
          name: 'link-gitlab-issue',
          icon: 'gitlab',
          label: __('GitLab: Link issue'),
          inputPlaceholder: 'https://git.example.com/group1/project1/-/issues/1',
        },
        form: {
          externalReferences: [mockedIssues[0].url],
        },
      },
      router: true,
    })

    expect(await wrapper.findByText('Assignee')).toBeInTheDocument()
    expect(wrapper.getByText('Benjamin Foo')).toBeInTheDocument()

    expect(wrapper.getByText('Milestone')).toBeInTheDocument()
    expect(wrapper.getByText('Frontend refactoring')).toBeInTheDocument()

    expect(wrapper.getByText('Labels')).toBeInTheDocument()
  })
})
