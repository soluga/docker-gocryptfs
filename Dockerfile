FROM golang:alpine AS builder
ENV GOCRYPTFS_VERSION v2.3.0

RUN apk add bash gcc git libc-dev openssl-dev
RUN go install github.com/rfjakob/gocryptfs@latest
WORKDIR src/github.com/rfjakob/gocryptfs

RUN git init
RUN git checkout "$GOCRYPTFS_VERSION"
RUN ./build.bash
RUN mv "$(go env GOPATH)/bin/gocryptfs" /bin/gocryptfs

FROM alpine:latest
RUN apk --no-cache add findutils

COPY --from=builder /bin/gocryptfs /usr/local/bin/gocryptfs
RUN apk --no-cache add fuse
RUN echo user_allow_other >> /etc/fuse.conf

COPY run.sh run.sh
RUN apk --no-cache add parallel

RUN mkdir /etc/gocryptfs
RUN adduser -D -u10001 gcfsuser
RUN chown  -R gcfsuser /etc/gocryptfs
USER gcfsuser

CMD ["./run.sh"]
