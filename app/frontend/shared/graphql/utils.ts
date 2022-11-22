// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

export const isGraphQLId = (id: string | number): id is string => {
  return typeof id !== 'number' && id.startsWith('gid://zammad/')
};

export const convertToGraphQLId = (type: string, id: number | string) => {
  return `gid://zammad/${type}/${id}`;
}

export const ensureGraphqlId = (type: string, id: number | string): string => {
  if (isGraphQLId(id)) {
    return id;
  }

  return convertToGraphQLId(type, id);
}

export const convertToGraphQLIds = (type: string, ids: (number | string)[]) => {
  return ids.map((id) => convertToGraphQLId(type, id));
}
