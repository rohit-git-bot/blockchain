FROM node:9-slim
WORKDIR /blockchain
COPY package.json /blockchain
RUN npm install
RUN npm install ejs
RUN npm install express
RUN npm install multer
RUN npm install web3
RUN npm version
COPY . /blockchain
CMD ["npm","start"]
