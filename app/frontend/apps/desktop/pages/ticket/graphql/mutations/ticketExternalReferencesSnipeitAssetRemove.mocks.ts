import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './ticketExternalReferencesSnipeitAssetRemove.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTicketExternalReferencesSnipeitAssetRemoveMutation(defaults: Mocks.MockDefaultsValue<Types.TicketExternalReferencesSnipeitAssetRemoveMutation, Types.TicketExternalReferencesSnipeitAssetRemoveMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketExternalReferencesSnipeitAssetRemoveDocument, defaults)
}

export function waitForTicketExternalReferencesSnipeitAssetRemoveMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketExternalReferencesSnipeitAssetRemoveMutation>(Operations.TicketExternalReferencesSnipeitAssetRemoveDocument)
}

export function mockTicketExternalReferencesSnipeitAssetRemoveMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TicketExternalReferencesSnipeitAssetRemoveDocument, message, extensions);
}
