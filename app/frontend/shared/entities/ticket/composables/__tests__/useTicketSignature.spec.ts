// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { nextTick, reactive } from 'vue'

import { FormHandlerExecution } from '#shared/components/Form/types.ts'
import type {
  FormHandlerFunctionData,
  FormHandlerFunctionReactivity,
} from '#shared/components/Form/types.ts'

import { useTicketSignature } from '../useTicketSignature.ts'

// The signature watcher uses `flush: 'post'`, so two ticks are needed:
// one for the reactive change, one for the post-flush callback.
const waitForPostFlushWatcher = async () => {
  await nextTick()
  await nextTick()
}

type MockEditorContext = {
  signature: { internalId: number; renderedBody: string } | null
  addSignature: ReturnType<typeof vi.fn>
  removeSignature: ReturnType<typeof vi.fn>
}

const createMockEditorContext = (): MockEditorContext =>
  reactive({
    signature: null,
    addSignature: vi.fn(),
    removeSignature: vi.fn(),
  })

const createMockFormNode = (editorContext: MockEditorContext) =>
  ({
    find: vi.fn().mockReturnValue({ context: editorContext }),
  }) as unknown as FormHandlerFunctionData['formNode']

const createMockReactivity = (): FormHandlerFunctionReactivity =>
  ({
    changeFields: { value: {} },
    schemaData: { fields: {}, flags: {} },
    updateSchemaDataField: vi.fn(),
  }) as unknown as FormHandlerFunctionReactivity

describe('useTicketSignature', () => {
  describe('signatureHandling for ticket create (email-out)', () => {
    it('sets up signature watcher on initial execution when group is pre-selected', async () => {
      const editorContext = createMockEditorContext()
      const formNode = createMockFormNode(editorContext)

      const { signatureHandling } = useTicketSignature('email-out')
      const handler = signatureHandling('body')

      // Simulate Initial execution with group_id and articleSenderType pre-set
      handler.callback(FormHandlerExecution.Initial, createMockReactivity(), {
        formNode,
        values: { group_id: 1, articleSenderType: 'email-out' },
        changedField: undefined,
        getNodeByName: vi.fn(),
        findNodeByName: vi.fn(),
      })

      // Simulate form updater updating the signature
      editorContext.signature = { internalId: 1, renderedBody: '<p>Signature 1</p>' }
      await waitForPostFlushWatcher()

      expect(editorContext.addSignature).toHaveBeenCalledWith({
        renderedBody: '<p>Signature 1</p>',
        internalId: 1,
      })
    })

    it('does not set up watcher on initial execution when no group is selected', async () => {
      const editorContext = createMockEditorContext()
      const formNode = createMockFormNode(editorContext)

      const { signatureHandling } = useTicketSignature('email-out')
      const handler = signatureHandling('body')

      handler.callback(FormHandlerExecution.Initial, createMockReactivity(), {
        formNode,
        values: { group_id: undefined, articleSenderType: 'email-out' },
        changedField: undefined,
        getNodeByName: vi.fn(),
        findNodeByName: vi.fn(),
      })

      editorContext.signature = { internalId: 1, renderedBody: '<p>Signature 1</p>' }
      await nextTick()

      expect(editorContext.addSignature).not.toHaveBeenCalled()
      // removeSignature is called when no group is selected (cleanup)
      expect(editorContext.removeSignature).toHaveBeenCalled()
    })

    it('does not set up watcher on initial execution when sender type does not match', async () => {
      const editorContext = createMockEditorContext()
      const formNode = createMockFormNode(editorContext)

      const { signatureHandling } = useTicketSignature('email-out')
      const handler = signatureHandling('body')

      handler.callback(FormHandlerExecution.Initial, createMockReactivity(), {
        formNode,
        values: { group_id: 1, articleSenderType: 'phone-out' },
        changedField: undefined,
        getNodeByName: vi.fn(),
        findNodeByName: vi.fn(),
      })

      editorContext.signature = { internalId: 1, renderedBody: '<p>Signature 1</p>' }
      await nextTick()

      expect(editorContext.addSignature).not.toHaveBeenCalled()
      expect(editorContext.removeSignature).toHaveBeenCalled()
    })

    it('sets up signature watcher when group_id changes', async () => {
      const editorContext = createMockEditorContext()
      const formNode = createMockFormNode(editorContext)

      const { signatureHandling } = useTicketSignature('email-out')
      const handler = signatureHandling('body')

      handler.callback(FormHandlerExecution.FieldChange, createMockReactivity(), {
        formNode,
        values: { group_id: 1, articleSenderType: 'email-out' },
        changedField: { name: 'group_id', newValue: 1, oldValue: null },
        getNodeByName: vi.fn(),
        findNodeByName: vi.fn(),
      })

      editorContext.signature = { internalId: 1, renderedBody: '<p>Signature 1</p>' }
      await waitForPostFlushWatcher()

      expect(editorContext.addSignature).toHaveBeenCalledWith({
        renderedBody: '<p>Signature 1</p>',
        internalId: 1,
      })
    })

    it('updates signature when group changes to one with different signature', async () => {
      const editorContext = createMockEditorContext()
      const formNode = createMockFormNode(editorContext)

      const { signatureHandling } = useTicketSignature('email-out')
      const handler = signatureHandling('body')

      // First group selection
      handler.callback(FormHandlerExecution.FieldChange, createMockReactivity(), {
        formNode,
        values: { group_id: 1, articleSenderType: 'email-out' },
        changedField: { name: 'group_id', newValue: 1, oldValue: null },
        getNodeByName: vi.fn(),
        findNodeByName: vi.fn(),
      })

      editorContext.signature = { internalId: 1, renderedBody: '<p>Signature 1</p>' }
      await waitForPostFlushWatcher()

      expect(editorContext.addSignature).toHaveBeenCalledWith({
        renderedBody: '<p>Signature 1</p>',
        internalId: 1,
      })

      // Change to second group
      handler.callback(FormHandlerExecution.FieldChange, createMockReactivity(), {
        formNode,
        values: { group_id: 2, articleSenderType: 'email-out' },
        changedField: { name: 'group_id', newValue: 2, oldValue: 1 },
        getNodeByName: vi.fn(),
        findNodeByName: vi.fn(),
      })

      editorContext.signature = { internalId: 2, renderedBody: '<p>Signature 2</p>' }
      await waitForPostFlushWatcher()

      expect(editorContext.addSignature).toHaveBeenLastCalledWith({
        renderedBody: '<p>Signature 2</p>',
        internalId: 2,
      })
    })

    it('removes signature when group changes to one without signature', async () => {
      const editorContext = createMockEditorContext()
      const formNode = createMockFormNode(editorContext)

      const { signatureHandling } = useTicketSignature('email-out')
      const handler = signatureHandling('body')

      // First group selection with signature
      handler.callback(FormHandlerExecution.FieldChange, createMockReactivity(), {
        formNode,
        values: { group_id: 1, articleSenderType: 'email-out' },
        changedField: { name: 'group_id', newValue: 1, oldValue: null },
        getNodeByName: vi.fn(),
        findNodeByName: vi.fn(),
      })

      editorContext.signature = { internalId: 1, renderedBody: '<p>Signature 1</p>' }
      await waitForPostFlushWatcher()

      // Change to group without signature
      handler.callback(FormHandlerExecution.FieldChange, createMockReactivity(), {
        formNode,
        values: { group_id: 2, articleSenderType: 'email-out' },
        changedField: { name: 'group_id', newValue: 2, oldValue: 1 },
        getNodeByName: vi.fn(),
        findNodeByName: vi.fn(),
      })

      editorContext.signature = null
      await waitForPostFlushWatcher()

      expect(editorContext.removeSignature).toHaveBeenCalled()
    })

    it('removes signature when sender type changes away from email-out', async () => {
      const editorContext = createMockEditorContext()
      const formNode = createMockFormNode(editorContext)

      const { signatureHandling } = useTicketSignature('email-out')
      const handler = signatureHandling('body')

      // Set up with email-out
      handler.callback(FormHandlerExecution.FieldChange, createMockReactivity(), {
        formNode,
        values: { group_id: 1, articleSenderType: 'email-out' },
        changedField: { name: 'group_id', newValue: 1, oldValue: null },
        getNodeByName: vi.fn(),
        findNodeByName: vi.fn(),
      })

      editorContext.signature = { internalId: 1, renderedBody: '<p>Signature 1</p>' }
      await waitForPostFlushWatcher()

      expect(editorContext.addSignature).toHaveBeenCalled()

      // Switch sender type away from email-out
      handler.callback(FormHandlerExecution.FieldChange, createMockReactivity(), {
        formNode,
        values: { group_id: 1, articleSenderType: 'phone-out' },
        changedField: { name: 'articleSenderType', newValue: 'phone-out', oldValue: 'email-out' },
        getNodeByName: vi.fn(),
        findNodeByName: vi.fn(),
      })

      expect(editorContext.removeSignature).toHaveBeenCalled()
    })

    it('ignores field changes that are not group_id or articleSenderType', async () => {
      const editorContext = createMockEditorContext()
      const formNode = createMockFormNode(editorContext)

      const { signatureHandling } = useTicketSignature('email-out')
      const handler = signatureHandling('body')

      handler.callback(FormHandlerExecution.FieldChange, createMockReactivity(), {
        formNode,
        values: { group_id: 1, articleSenderType: 'email-out' },
        changedField: { name: 'title', newValue: 'Test', oldValue: '' },
        getNodeByName: vi.fn(),
        findNodeByName: vi.fn(),
      })

      expect(editorContext.addSignature).not.toHaveBeenCalled()
      expect(editorContext.removeSignature).not.toHaveBeenCalled()
    })
  })

  describe('signatureHandling for ticket detail view (email)', () => {
    it('sets up signature watcher when article type changes to email', async () => {
      const editorContext = createMockEditorContext()
      const formNode = createMockFormNode(editorContext)

      const { signatureHandling } = useTicketSignature('email')
      const handler = signatureHandling('body')

      handler.callback(FormHandlerExecution.FieldChange, createMockReactivity(), {
        formNode,
        values: {
          group_id: 1,
          article: { articleType: 'email' },
        },
        changedField: { name: 'articleSenderType', newValue: 'email', oldValue: undefined },
        getNodeByName: vi.fn(),
        findNodeByName: vi.fn(),
      })

      editorContext.signature = { internalId: 1, renderedBody: '<p>Signature</p>' }
      await waitForPostFlushWatcher()

      expect(editorContext.addSignature).toHaveBeenCalledWith({
        renderedBody: '<p>Signature</p>',
        internalId: 1,
      })
    })

    it('sets up signature watcher when group_id changes in detail view', async () => {
      const editorContext = createMockEditorContext()
      const formNode = createMockFormNode(editorContext)

      const { signatureHandling } = useTicketSignature('email')
      const handler = signatureHandling('body')

      handler.callback(FormHandlerExecution.FieldChange, createMockReactivity(), {
        formNode,
        values: {
          group_id: 2,
          article: { articleType: 'email' },
        },
        changedField: { name: 'group_id', newValue: 2, oldValue: 1 },
        getNodeByName: vi.fn(),
        findNodeByName: vi.fn(),
      })

      editorContext.signature = { internalId: 2, renderedBody: '<p>New Group Signature</p>' }
      await waitForPostFlushWatcher()

      expect(editorContext.addSignature).toHaveBeenCalledWith({
        renderedBody: '<p>New Group Signature</p>',
        internalId: 2,
      })
    })
  })
})
