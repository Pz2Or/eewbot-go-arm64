FROM ubuntu:latest as builder
WORKDIR /build

COPY . ./

RUN apt-get update \
 && apt-get install -y ca-certificates \
 && sed -i.bak -r 's!(deb|deb-src) \S+!\1 https://mirrors.xtom.com.hk/ubuntu/!' /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -y golang \
 && go build -ldflags="-s -w" -trimpath -o eewbot main.go

FROM ubuntu:latest
WORKDIR /app


RUN apt-get update \
 && apt-get install -y ca-certificates \
 && sed -i.bak -r 's!(deb|deb-src) \S+!\1 https://mirrors.xtom.com.hk/ubuntu/!' /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -y curl tini xvfb graphicsmagick-imagemagick-compat wget unzip \
 && groupadd -g 987 app \
 && useradd -d /app -s /bin/sh -u 987 -g app app \
 && wget https://github.com/ingen084/KyoshinEewViewerIngen/releases/latest/download/KyoshinEewViewer-ubuntu-arm64.zip \
 && unzip KyoshinEewViewer-ubuntu-arm64.zip \
 && rm -f KyoshinEewViewer-ubuntu-arm64.zip \
 && apt-get purge -y wget unzip \
 && apt-get autoremove --purge -y \
 && apt-get clean \
 && mkdir "hooks" \
 && chown -R app:app /app

COPY --from=builder /build/eewbot /app/hooks/eewbot
COPY --chown=app:app . .

RUN chmod +x /app/hooks/*

USER app
CMD ["tini", "--", "xvfb-run", "-s", "-ac -screen 0 1280x800x24", "./KyoshinEewViewer"]
