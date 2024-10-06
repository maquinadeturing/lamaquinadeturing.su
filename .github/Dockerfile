# Use the official Node.js image as the base image
FROM ubuntu:24.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    nodejs npm \
    ruby-full build-essential \
    imagemagick libmagickwand-dev \
    wget \
    gnupg

RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' \
    && apt-get update && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

RUN gem install bundler

# Install Mermaid CLI globally
RUN npm install -g @mermaid-js/mermaid-cli
RUN npm install -g @puppeteer/browsers

# Set the working directory
WORKDIR /workspace

ENTRYPOINT ["/bin/bash"]
