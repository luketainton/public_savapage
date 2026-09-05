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

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 631 8631 8632 9100
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
