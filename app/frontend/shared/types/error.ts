// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { GraphQLErrorExtensions } from 'graphql'
import type { Except } from 'type-fest'
import type { UserError } from '@shared/graphql/types'

export enum GraphQLErrorTypes {
  UnkownError = 'Exceptions::UnkownError',
  NetworkError = 'Exceptions::NetworkError',

  // This exception actually means 'NotAuthenticated'
  NotAuthorized = 'Exceptions::NotAuthorized',
}

export type GraphQLErrorTypeKeys = keyof GraphQLErrorTypes

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

export enum ErrorStatusCodes {
  'Forbidden' = 403,
  'NotFound' = 404,
}

export type UserErrors = Except<UserError, '__typename'>[]
export interface UserFieldError {
  field: string
  message: string
}
export type UserFieldErrors = UserFieldError[]
