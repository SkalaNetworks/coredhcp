ARG PROJECT=coredhcp

FROM golang:1.19-buster AS build

ARG PROJECT
ARG USER=$PROJECT
ARG UID=1000

RUN adduser               \
  --disabled-password     \
  --gecos ""              \
  --home "/nonexistent"   \
  --shell "/sbin/nologin" \
  --no-create-home        \
  --uid $UID              \
  $USER

WORKDIR $GOPATH/src/$PROJECT/
COPY . .

RUN go mod download && go mod verify
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -ldflags '-w -s' -o /bin/main cmds/coredhcp/main.go

FROM scratch

ARG PROJECT
WORKDIR /

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /etc/group /etc/group
COPY --from=build /bin/main /bin/$PROJECT

USER $USER:$USER

EXPOSE 80

ENTRYPOINT ["./bin/coredhcp"]

