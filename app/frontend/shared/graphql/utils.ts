// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

export const isGraphQLId = (id: unknown): id is string => {
  return typeof id === 'string' && id.startsWith('gid://zammad/')
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

export const parseGraphqlId = (id: string): { relation: string; id: number } => {
  const [relation, idString] = id.slice('gid://zammad/'.length).split('/');

  return {
    relation,
    id: parseInt(idString, 10),
  };
}

export const getIdFromGraphQLId = (graphqlId: string) => {
  const parsedGraphqlId = parseGraphqlId(graphqlId);
  return parsedGraphqlId.id;
}

export const convertToGraphQLIds = (type: string, ids: (number | string)[]) => {
  return ids.map((id) => convertToGraphQLId(type, id));
}
