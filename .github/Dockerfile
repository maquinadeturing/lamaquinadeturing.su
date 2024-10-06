FROM ubuntu:24.04

ENV PUPPETEER_CACHE_DIR=/puppeteer

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    nodejs npm \
    ruby-full build-essential \
    imagemagick libmagickwand-dev \
    wget \
    gnupg \
    git

RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update && apt-get install -y google-chrome-stable \
    \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN gem install bundler \
    && npm install -g @mermaid-js/mermaid-cli @puppeteer/browsers \
    && npx @puppeteer/browsers install chrome-headless-shell \
    && chmod -R 755 ${PUPPETEER_CACHE_DIR} \
    && mv $(which mmdc) $(which mmdc)-sandbox \
    && echo '#!/bin/bash\nmmdc-sandbox "$@" --puppeteerConfigFile <(echo "{ \"args\": [\"--no-sandbox\"] }")' > /usr/bin/mmdc \
    && chmod +x /usr/bin/mmdc

WORKDIR /workspace

ENTRYPOINT ["/bin/bash"]
