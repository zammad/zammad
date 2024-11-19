// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
import '#tests/graphql/builders/mocks.ts'

import { createPinia, setActivePinia } from 'pinia'
import { effectScope } from 'vue'

import { generateObjectData } from '#tests/graphql/builders/index.ts'

import { useObjectAttributes } from '#shared/entities/object-attributes/composables/useObjectAttributes.ts'
import { waitForObjectManagerFrontendAttributesQueryCalls } from '#shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.mocks.ts'
import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import {
  type HistoryRecordEvent,
  type Job,
  type ObjectClass,
  type PostmasterFilter,
  type Trigger,
  type User,
  type TicketArticle,
  EnumObjectManagerObjects,
} from '#shared/graphql/types.ts'
import { textTruncate } from '#shared/utils/helpers.ts'

import { useHistoryEvents } from '../composables/useHistoryEvents.ts'
import HistoryEventDetailsEmail from '../HistoryEventDetails/HistoryEventDetailsEmail.vue'
import HistoryEventDetailsMerge from '../HistoryEventDetails/HistoryEventDetailsMerge.vue'
import HistoryEventDetailsReaction from '../HistoryEventDetails/HistoryEventDetailsReaction.vue'
import HistoryEventDetailsTimeTriggerPerformed from '../HistoryEventDetails/HistoryEventDetailsTimeTriggerPerformed.vue'

const scope = effectScope()

describe('useHistoryEvents', () => {
  describe('issuedBySystemService', () => {
    it('returns true in case issuer is a system service (e.g. trigger)', () => {
      const issuer: Trigger = {
        __typename: 'Trigger',
        id: 'gid://zammad/Trigger/1',
        internalId: 1,
        name: 'Trigger 1',
        createdAt: '2022-01-01T00:00:00Z',
        updatedAt: '2022-01-01T00:00:00Z',
      }

      const { issuedBySystemService } = useHistoryEvents()

      expect(issuedBySystemService(issuer)).toBe(true)
    })

    it('returns false in case issuer is a user', () => {
      const issuer: Partial<User> = {
        __typename: 'User',
        id: 'gid://zammad/User/1',
        internalId: 1,
        firstname: 'John',
        lastname: 'Doe',
      }

      const { issuedBySystemService } = useHistoryEvents()

      expect(issuedBySystemService(issuer)).toBe(false)
    })
  })

  describe('issuedBySystemUser', () => {
    it('returns true in case issuer is a system user', () => {
      const issuer: Partial<User> = {
        __typename: 'User',
        id: 'gid://zammad/User/1',
        internalId: 1,
        firstname: 'John',
        lastname: 'Doe',
      }

      const { issuedBySystemUser } = useHistoryEvents()

      expect(issuedBySystemUser(issuer)).toBe(true)
    })

    it('returns false in case issuer is a regular user', () => {
      const issuer: Partial<User> = {
        __typename: 'User',
        id: 'gid://zammad/User/2',
        internalId: 2,
        firstname: 'Jane',
        lastname: 'Doe',
      }

      const { issuedBySystemUser } = useHistoryEvents()

      expect(issuedBySystemUser(issuer)).toBe(false)
    })

    it('returns false in case issuer is a system service', () => {
      const issuer: Trigger = {
        __typename: 'Trigger',
        id: 'gid://zammad/Trigger/1',
        internalId: 1,
        name: 'Trigger 1',
        createdAt: '2022-01-01T00:00:00Z',
        updatedAt: '2022-01-01T00:00:00Z',
      }

      const { issuedBySystemUser } = useHistoryEvents()

      expect(issuedBySystemUser(issuer)).toBe(false)
    })
  })

  describe('getIssuerName', () => {
    it('returns system in case issuer is the system user', () => {
      const issuer: Partial<User> = {
        __typename: 'User',
        id: 'gid://zammad/User/1',
        internalId: 1,
        firstname: '',
        lastname: '',
        fullname: '-',
      }

      const { getIssuerName } = useHistoryEvents()

      expect(getIssuerName(issuer)).toBe('System')
    })

    it('returns user fullname in case issuer is a user', () => {
      const issuer: Partial<User> = {
        __typename: 'User',
        id: 'gid://zammad/User/2',
        internalId: 2,
        firstname: 'John',
        lastname: 'Doe',
        fullname: 'John Doe',
      }

      const { getIssuerName } = useHistoryEvents()

      expect(getIssuerName(issuer)).toBe('John Doe')
    })

    it('returns issuer name in case issuer is a job', () => {
      const issuer: Job = {
        __typename: 'Job',
        id: 'gid://zammad/Job/1',
        internalId: 1,
        name: 'Dummy',
        createdAt: '2022-01-01T00:00:00Z',
        updatedAt: '2022-01-01T00:00:00Z',
      }

      const { getIssuerName } = useHistoryEvents()

      expect(getIssuerName(issuer)).toBe('Scheduler: Dummy')
    })

    it('returns issuer name in case issuer is a postmaster filter', () => {
      const issuer: PostmasterFilter = {
        __typename: 'PostmasterFilter',
        id: 'gid://zammad/PostmasterFilter/1',
        internalId: 1,
        name: 'Internal Mails',
        createdAt: '2022-01-01T00:00:00Z',
        updatedAt: '2022-01-01T00:00:00Z',
      }

      const { getIssuerName } = useHistoryEvents()

      expect(getIssuerName(issuer)).toBe('Postmaster Filter: Internal Mails')
    })

    it('returns issuer name in case issuer is a trigger', () => {
      const issuer: Trigger = {
        __typename: 'Trigger',
        id: 'gid://zammad/Trigger/1',
        internalId: 1,
        name: 'Move to archive',
        createdAt: '2022-01-01T00:00:00Z',
        updatedAt: '2022-01-01T00:00:00Z',
      }

      const { getIssuerName } = useHistoryEvents()

      expect(getIssuerName(issuer)).toBe('Trigger: Move to archive')
    })

    it('returns issuer name in case issuer is a deleted trigger', () => {
      const issuer: ObjectClass = {
        __typename: 'ObjectClass',
        klass: 'Trigger',
        info: 'Move to archive',
      }

      const { getIssuerName } = useHistoryEvents()

      expect(getIssuerName(issuer)).toBe('Trigger: Move to archive')
    })
  })

  describe('getEventOutput', () => {
    it('throws an error in case event action is missing', () => {
      const event: HistoryRecordEvent = {
        __typename: 'HistoryRecordEvent',
        action: '',
        createdAt: '2022-01-01T00:00:00Z',
        object: {},
      }

      const { getEventOutput } = useHistoryEvents()

      expect(() => getEventOutput(event)).toThrowError(
        'Event action is missing or not found in event actions lookup!',
      )
    })

    describe('added', () => {
      it('returns output for e.g. tag creation', () => {
        const event: HistoryRecordEvent = {
          __typename: 'HistoryRecordEvent',
          action: 'added',
          createdAt: '2022-01-01T00:00:00Z',
          changes: {
            from: '',
            to: 'dummy',
          },
          object: {
            __typename: 'ObjectClass',
            klass: 'Ticket',
          },
          attribute: 'tag',
        }

        const { getEventOutput } = useHistoryEvents()

        expect(getEventOutput(event)).toEqual({
          actionName: 'added',
          component: undefined,
          entityName: 'Ticket',
          attributeName: 'Tag',
          details: 'dummy',
        })
      })
    })

    describe('checklist-item-checked', () => {
      it('returns output for e.g. checklist item checked', () => {
        const event: HistoryRecordEvent = {
          __typename: 'HistoryRecordEvent',
          action: 'checklist_item_checked',
          createdAt: '2022-01-01T00:00:00Z',
          changes: {
            from: 'print tickets',
            to: 'true',
          },
          object: {},
        }

        const { getEventOutput } = useHistoryEvents()

        expect(getEventOutput(event)).toEqual({
          actionName: 'checked',
          component: undefined,
          entityName: 'Checklist Item',
          details: 'print tickets',
        })
      })

      it('returns output for e.g. checklist item unchecked', () => {
        const event: HistoryRecordEvent = {
          __typename: 'HistoryRecordEvent',
          action: 'checklist_item_checked',
          createdAt: '2022-01-01T00:00:00Z',
          changes: {
            from: 'print tickets',
            to: 'false',
          },
          object: {},
        }

        const { getEventOutput } = useHistoryEvents()

        expect(getEventOutput(event)).toEqual({
          actionName: 'unchecked',
          component: undefined,
          entityName: 'Checklist Item',
          details: 'print tickets',
        })
      })
    })

    describe('created-mention', () => {
      it('returns output for e.g. mention creation', () => {
        const event: HistoryRecordEvent = {
          __typename: 'HistoryRecordEvent',
          action: 'created_mention',
          createdAt: '2022-01-01T00:00:00Z',
          changes: {
            from: '',
            to: 'Dummy',
          },
          object: {
            __typename: 'User',
            id: 'gid://zammad/User/2',
            internalId: 2,
            firstname: 'John',
            lastname: 'Doe',
            fullname: 'John Doe',
            active: true,
            createdAt: '2022-01-01T00:00:00Z',
            updatedAt: '2022-01-01T00:00:00Z',
            policy: {
              update: true,
              destroy: false,
            },
          },
        }

        const { getEventOutput } = useHistoryEvents()

        expect(getEventOutput(event)).toEqual({
          actionName: 'created',
          component: undefined,
          description: 'Mention for',
          details: 'John Doe',
        })
      })
    })

    describe('created', () => {
      it('returns output for e.g. ticket creation', () => {
        const event: HistoryRecordEvent = {
          __typename: 'HistoryRecordEvent',
          action: 'created',
          createdAt: '2022-01-01T00:00:00Z',
          object: createDummyTicket(),
        }

        const { getEventOutput } = useHistoryEvents()

        expect(getEventOutput(event)).toEqual({
          actionName: 'created',
          component: undefined,
          entityName: 'Ticket',
          details: '',
        })
      })

      it('returns output for e.g. deleted entity', () => {
        const event: HistoryRecordEvent = {
          __typename: 'HistoryRecordEvent',
          action: 'created',
          createdAt: '2022-01-01T00:00:00Z',
          object: {
            __typename: 'ObjectClass',
            klass: 'Ticket',
          },
        }

        const { getEventOutput } = useHistoryEvents()

        expect(getEventOutput(event)).toEqual({
          actionName: 'created',
          component: undefined,
          entityName: 'Ticket',
          details: '',
        })
      })
    })

    describe('email', () => {
      it('returns output for e.g. email sent', () => {
        const event: HistoryRecordEvent = {
          __typename: 'HistoryRecordEvent',
          action: 'email',
          createdAt: '2022-01-01T00:00:00Z',
          changes: {
            from: '',
            to: 'John Doe <john.doe@example.org>',
          },
          object: {},
        }

        const { getEventOutput } = useHistoryEvents()

        expect(getEventOutput(event)).toEqual({
          actionName: 'email',
          component: HistoryEventDetailsEmail,
          details: 'John Doe <john.doe@example.org>',
        })
      })
    })

    describe('merged-into', () => {
      it('returns output for e.g. ticket merge', () => {
        const event: HistoryRecordEvent = {
          __typename: 'HistoryRecordEvent',
          action: 'merged_into',
          createdAt: '2022-01-01T00:00:00Z',
          object: createDummyTicket(),
        }

        const { getEventOutput } = useHistoryEvents()

        expect(getEventOutput(event)).toEqual({
          actionName: 'merged-into',
          component: HistoryEventDetailsMerge,
          details: '#89002',
          link: '/tickets/1',
        })
      })
    })

    describe('notification', () => {
      it('returns output for e.g. notification', () => {
        const event: HistoryRecordEvent = {
          __typename: 'HistoryRecordEvent',
          action: 'notification',
          createdAt: '2022-01-01T00:00:00Z',
          changes: {
            from: '',
            to: 'dummy@example.com(update:online,email)',
          },
          object: {},
        }

        const { getEventOutput } = useHistoryEvents()

        expect(getEventOutput(event)).toEqual({
          actionName: 'notification',
          component: undefined,
          details: 'dummy@example.com',
          additionalDetails: 'update:online,email',
        })
      })
    })

    describe('received-merge', () => {
      it('returns output for e.g. ticket merge', () => {
        const event: HistoryRecordEvent = {
          __typename: 'HistoryRecordEvent',
          action: 'received_merge',
          createdAt: '2022-01-01T00:00:00Z',
          object: createDummyTicket(),
        }

        const { getEventOutput } = useHistoryEvents()

        expect(getEventOutput(event)).toEqual({
          actionName: 'received-merge',
          component: HistoryEventDetailsMerge,
          details: '#89002',
          link: '/tickets/1',
        })
      })
    })

    describe('removed-mention', () => {
      it('returns output for e.g. mention removal', () => {
        const event: HistoryRecordEvent = {
          __typename: 'HistoryRecordEvent',
          action: 'removed_mention',
          createdAt: '2022-01-01T00:00:00Z',
          changes: {
            from: '',
            to: '',
          },
          object: {
            __typename: 'User',
            id: 'gid://zammad/User/2',
            internalId: 2,
            firstname: 'John',
            lastname: 'Doe',
            fullname: 'John Doe',
            active: true,
            createdAt: '2022-01-01T00:00:00Z',
            updatedAt: '2022-01-01T00:00:00Z',
            policy: {
              update: true,
              destroy: false,
            },
          },
        }

        const { getEventOutput } = useHistoryEvents()

        expect(getEventOutput(event)).toEqual({
          actionName: 'removed',
          component: undefined,
          description: 'Mention for',
          details: 'John Doe',
        })
      })
    })

    describe('removed', () => {
      it('returns output for e.g. checklist item removal', () => {
        const event: HistoryRecordEvent = {
          __typename: 'HistoryRecordEvent',
          action: 'removed',
          createdAt: '2022-01-01T00:00:00Z',
          changes: {
            from: '',
            to: 'dummy',
          },
          object: {
            __typename: 'ObjectClass',
            klass: 'ChecklistItem',
            info: 'dummy',
          },
        }

        const { getEventOutput } = useHistoryEvents()

        expect(getEventOutput(event)).toEqual({
          actionName: 'removed',
          component: undefined,
          attributeName: '',
          entityName: 'Checklist Item',
          details: 'dummy',
        })
      })
    })

    describe('time-trigger-performed', () => {
      it('returns output for e.g. reminder reached', () => {
        const event: HistoryRecordEvent = {
          __typename: 'HistoryRecordEvent',
          action: 'time_trigger_performed',
          createdAt: '2022-01-01T00:00:00Z',
          changes: {
            from: 'reminder_reached',
            to: '',
          },
          object: {},
        }

        const { getEventOutput } = useHistoryEvents()

        expect(getEventOutput(event)).toEqual({
          actionName: 'triggered',
          component: HistoryEventDetailsTimeTriggerPerformed,
          description: 'Triggered because pending reminder was reached',
        })
      })

      it('returns output for e.g. ticket escalation', () => {
        const event: HistoryRecordEvent = {
          __typename: 'HistoryRecordEvent',
          action: 'time_trigger_performed',
          createdAt: '2022-01-01T00:00:00Z',
          changes: {
            from: 'escalation',
            to: '',
          },
          object: {},
        }

        const { getEventOutput } = useHistoryEvents()

        expect(getEventOutput(event)).toEqual({
          actionName: 'triggered',
          component: HistoryEventDetailsTimeTriggerPerformed,
          description: 'Triggered because ticket was escalated',
        })
      })

      it('returns output for e.g. ticket escalation warning', () => {
        const event: HistoryRecordEvent = {
          __typename: 'HistoryRecordEvent',
          action: 'time_trigger_performed',
          createdAt: '2022-01-01T00:00:00Z',
          changes: {
            from: 'escalation_warning',
            to: '',
          },
          object: {},
        }

        const { getEventOutput } = useHistoryEvents()

        expect(getEventOutput(event)).toEqual({
          actionName: 'triggered',
          component: HistoryEventDetailsTimeTriggerPerformed,
          description: 'Triggered because ticket will escalate soon',
        })
      })

      it('returns output for e.g. time event reached', () => {
        const event: HistoryRecordEvent = {
          __typename: 'HistoryRecordEvent',
          action: 'time_trigger_performed',
          createdAt: '2022-01-01T00:00:00Z',
          changes: {
            from: '',
            to: '',
          },
          object: {},
        }

        const { getEventOutput } = useHistoryEvents()

        expect(getEventOutput(event)).toEqual({
          actionName: 'triggered',
          component: HistoryEventDetailsTimeTriggerPerformed,
          description: 'Triggered because time event was reached',
        })
      })
    })

    describe('updated', () => {
      beforeEach(async () => {
        setActivePinia(createPinia())

        await scope.run(async () => {
          useObjectAttributes(EnumObjectManagerObjects.Ticket)

          await waitForObjectManagerFrontendAttributesQueryCalls()
        })
      })

      it('returns output for e.g. ticket title update', async () => {
        await scope.run(async () => {
          const event: HistoryRecordEvent = {
            __typename: 'HistoryRecordEvent',
            action: 'updated',
            createdAt: '2022-01-01T00:00:00Z',
            object: createDummyTicket(),
            attribute: 'title',
            changes: {
              from: '',
              to: 'Dummy',
            },
          }

          const { getEventOutput } = useHistoryEvents()

          expect(getEventOutput(event)).toEqual({
            actionName: 'updated',
            component: undefined,
            entityName: 'Ticket',
            attributeName: 'Title',
            details: '-',
            additionalDetails: 'Dummy',
            showSeparator: true,
          })
        })
      })

      it('returns output for e.g. ticket pending time update', async () => {
        await scope.run(async () => {
          const event: HistoryRecordEvent = {
            __typename: 'HistoryRecordEvent',
            action: 'updated',
            createdAt: '2022-01-01T00:00:00Z',
            object: createDummyTicket(),
            attribute: 'close_at',
            changes: {
              from: '',
              to: '2022-01-01T00:00:00Z',
            },
          }

          const { getEventOutput } = useHistoryEvents()

          expect(getEventOutput(event)).toEqual({
            actionName: 'updated',
            component: undefined,
            entityName: 'Ticket',
            attributeName: 'Closing time',
            details: '-',
            additionalDetails: '2022-01-01 00:00',
            showSeparator: true,
          })
        })
      })

      it('returns output for e.g. ticket group update', async () => {
        await scope.run(async () => {
          const event: HistoryRecordEvent = {
            __typename: 'HistoryRecordEvent',
            action: 'updated',
            createdAt: '2022-01-01T00:00:00Z',
            object: createDummyTicket(),
            attribute: 'group',
            changes: {
              from: 'Group1::Group2',
              to: 'Group3::Group4',
            },
          }

          const { getEventOutput } = useHistoryEvents()

          expect(getEventOutput(event)).toEqual({
            actionName: 'updated',
            component: undefined,
            entityName: 'Ticket',
            attributeName: 'Group',
            details: 'Group1 › Group2',
            additionalDetails: 'Group3 › Group4',
            showSeparator: true,
          })
        })
      })
    })

    describe('WhatsApp reaction', () => {
      const article = generateObjectData<TicketArticle>('TicketArticle')

      describe('created', () => {
        it('returns output for e.g. reaction creation', () => {
          const event: HistoryRecordEvent = {
            __typename: 'HistoryRecordEvent',
            action: 'created',
            createdAt: '2022-01-01T00:00:00Z',
            object: article,
            attribute: 'reaction',
            changes: {
              from: 'Dummy',
              to: '👍',
            },
          }

          const { getEventOutput } = useHistoryEvents()

          expect(getEventOutput(event)).toEqual({
            actionName: 'reacted-with',
            component: HistoryEventDetailsReaction,
            description: '👍',
            details: textTruncate(article.body),
            additionalDetails: 'Dummy',
          })
        })

        it('returns output for e.g. reaction creation without emoji', () => {
          const event: HistoryRecordEvent = {
            __typename: 'HistoryRecordEvent',
            action: 'created',
            createdAt: '2022-01-01T00:00:00Z',
            object: article,
            attribute: 'reaction',
            changes: {
              from: 'Dummy',
              to: '',
            },
          }

          const { getEventOutput } = useHistoryEvents()

          expect(getEventOutput(event)).toEqual({
            actionName: 'reacted',
            component: HistoryEventDetailsReaction,
            description: '',
            details: textTruncate(article.body),
            additionalDetails: 'Dummy',
          })
        })
      })

      describe('updated', () => {
        beforeEach(() => {
          setActivePinia(createPinia())
        })

        it('returns output for e.g. reaction update', async () => {
          await scope.run(async () => {
            const event: HistoryRecordEvent = {
              __typename: 'HistoryRecordEvent',
              action: 'updated',
              createdAt: '2022-01-01T00:00:00Z',
              object: article,
              attribute: 'reaction',
              changes: {
                from: 'Dummy',
                to: '🙏',
              },
            }

            const { getEventOutput } = useHistoryEvents()

            expect(getEventOutput(event)).toEqual({
              actionName: 'changed-reaction-to',
              component: HistoryEventDetailsReaction,
              description: '🙏',
              details: textTruncate(article.body),
              additionalDetails: 'Dummy',
            })
          })
        })

        it('returns output for e.g. reaction creation without emoji', async () => {
          await scope.run(async () => {
            const event: HistoryRecordEvent = {
              __typename: 'HistoryRecordEvent',
              action: 'updated',
              createdAt: '2022-01-01T00:00:00Z',
              object: article,
              attribute: 'reaction',
              changes: {
                from: 'Dummy',
                to: '',
              },
            }

            const { getEventOutput } = useHistoryEvents()

            expect(getEventOutput(event)).toEqual({
              actionName: 'changed-reaction',
              component: HistoryEventDetailsReaction,
              description: '',
              details: textTruncate(article.body),
              additionalDetails: 'Dummy',
            })
          })
        })
      })

      describe('removed', () => {
        it('returns output for e.g. reaction removal', () => {
          const event: HistoryRecordEvent = {
            __typename: 'HistoryRecordEvent',
            action: 'removed',
            createdAt: '2022-01-01T00:00:00Z',
            object: article,
            attribute: 'reaction',
            changes: {
              from: 'Dummy',
              to: '',
            },
          }

          const { getEventOutput } = useHistoryEvents()

          expect(getEventOutput(event)).toEqual({
            actionName: 'removed-reaction',
            component: HistoryEventDetailsReaction,
            details: textTruncate(article.body),
            additionalDetails: 'Dummy',
          })
        })
      })
    })
  })
})
