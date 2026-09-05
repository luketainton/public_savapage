FROM debian:bookworm

ARG SAVAPAGE_VERSION=1.7.0

RUN apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
        apt-utils binutils cpio cups cups-bsd debianutils \
        default-jdk-headless findutils gnupg gzip hplip imagemagick \
        iputils-ping libheif-examples librsvg2-bin perl poppler-utils \
        qpdf supervisor vim-tiny wkhtmltopdf curl \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -rmd /opt/savapage -s /bin/bash -G lpadmin savapage \
    && chown -R savapage:savapage /opt/savapage

COPY savapage-setup-${SAVAPAGE_VERSION}-final-linux-x64.bin /opt/savapage/savapage-setup.bin

USER savapage
RUN bash /opt/savapage/savapage-setup.bin -n

USER root
RUN /opt/savapage/server/bin/linux-x64/roottasks pam

RUN mkdir -p /opt/savapage/defaults \
    && cp -a /opt/savapage/server/data /opt/savapage/defaults/data \
    && cp -a /etc/cups /opt/savapage/defaults/cups

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY cupsd-run.sh /usr/local/bin/cupsd-run.sh
COPY savapage-run.sh /usr/local/bin/savapage-run.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod 755 /usr/local/bin/docker-entrypoint.sh /usr/local/bin/cupsd-run.sh /usr/local/bin/savapage-run.sh

EXPOSE 631 8631 8632 9100
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
