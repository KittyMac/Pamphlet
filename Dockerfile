FROM swiftarm/swift:5.6.2-ubuntu-focal as builder

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
    apt-get install -y \
    libpq-dev \
    libpng-dev \
    libjpeg-dev \
    libjavascriptcoregtk-4.0-dev

RUN ls /usr/include/

WORKDIR /root/Pamphlet
COPY ./Makefile ./Makefile
COPY ./Package.swift ./Package.swift
COPY ./Plugins ./Plugins
COPY ./Sources ./Sources
COPY ./Tests ./Tests

RUN swift package update
RUN swift test
