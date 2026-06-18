FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
ARG REACT_APP_HELLO_URL=http://localhost:3001
ARG REACT_APP_PROFILE_URL=http://localhost:3002
ENV REACT_APP_HELLO_URL=$REACT_APP_HELLO_URL
ENV REACT_APP_PROFILE_URL=$REACT_APP_PROFILE_URL
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]