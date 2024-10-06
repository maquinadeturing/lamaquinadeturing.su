# Use the official Node.js image as the base image
FROM ubuntu:24.04

# Install Mermaid CLI globally
RUN apt-get update && apt-get install -y nodejs npm
RUN npm install -g @mermaid-js/mermaid-cli

# Install Ruby and Bundler
RUN apt-get install -y ruby-full build-essential
RUN gem install bundler

# Install MagickWand
RUN apt-get install -y imagemagick libmagickwand-dev

# Set the working directory
WORKDIR /workspace

ENTRYPOINT ["/bin/bash"]
