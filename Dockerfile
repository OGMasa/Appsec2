<<<<<<< HEAD
FROM node:20-alpine
ENV NODE_ENV=debug
=======
FROM node:22-alpine
ENV NODE_ENV=production
>>>>>>> 75166cf76f3e2a84c947d9c63b15a42e416ccb6d
WORKDIR /usr/src/app
COPY ["package.json", "package-lock.json*", "npm-shrinkwrap.json*", "./"]
RUN apk add python3 py3-pip build-base
RUN npm install --omit=dev && mv node_modules ../
FROM node:22
ENV NODE_ENV=production
WORKDIR /usr/src/app
COPY ["package.json", "package-lock.json*", "npm-shrinkwrap.json*", "./"]
# RUN apk add python3 py3-pip build-base
RUN npm install --production && mv node_modules ../
COPY . .
EXPOSE 3000
RUN chown -R node /usr/src/app
USER node
CMD ["npm", "start"]
