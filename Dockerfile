ARG NODE_VERSION=22.18.0

FROM node:${NODE_VERSION}-slim AS base

ARG PORT=3000

WORKDIR /nuxt-app

# build
FROM base AS build

COPY package*.json .
RUN npm install

COPY . .

RUN npm run build

# RUN
FROM base

ENV PORT=$PORT
ENV NODE_ENV=production

COPY --from=build ./nuxt-app/.output /nuxt-app/.output

EXPOSE ${PORT}

CMD ["node", ".output/server/index.mjs"]


