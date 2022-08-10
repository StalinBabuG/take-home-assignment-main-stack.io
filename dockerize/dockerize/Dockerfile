# syntax=docker/dockerfile:1
## Docker multistage configuration file 

## Building the image with the source code

FROM golang:1.19-alpine AS build

RUN mkdir -p /dockerize
WORKDIR /dockerize 

COPY stack.io/dockerize/go.mod ./
COPY stack.io/dockerize/go.sum ./
RUN go mod download

COPY stack.io/dockerize/ ./

RUN go build -o /web_server

## Deploying the executable into the image 

FROM alpine:latest

WORKDIR /

COPY --from=build /web_server /web_server

CMD [ "/web_server" ] 