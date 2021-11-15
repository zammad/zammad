// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { GraphQLErrorExtensions } from 'graphql'

export enum GraphQLErrorTypes {
  UnkownError = 'Exceptions::UnkownError',
  NetworkError = 'Exceptions::NetworkError',
  NotAuthorized = 'Exceptions::NotAuthorized',
}

export type GraphQLErrorTypeKeys = keyof GraphQLErrorTypes | 'test'

export interface GraphQLErrorExtensionsHandler {
  type: GraphQLErrorTypes
  backtrace: string
}

export interface GraphQLErrorReport {
  message: string
  extensions: GraphQLErrorExtensions
}
export interface GraphQLHandlerError {
  type: GraphQLErrorTypes
  message?: string
}
