# ---------- Stage 1: build ----------
# Uses an image that contains the Go compiler.
FROM golang:1.22-alpine AS build
WORKDIR /src
COPY go.mod main.go ./
# Static binary so it can run in an empty image
RUN CGO_ENABLED=0 go build -o /app main.go

# ---------- Stage 2: run ----------
# "scratch" is an empty image: only our binary goes in.
FROM scratch
COPY --from=build /app /app
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["/app"]
