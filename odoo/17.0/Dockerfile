FROM ubuntu:jammy
LABEL maintainer="Ernesto Jordan Borjas <ernesto@soltein.mx>"

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]
# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG en_US.UTF-8
# Retrieve the target architecture to install the correct wkhtmltopdf package
ARG TARGETARCH

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        unzip \
        gcc \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libssl-dev \
        node-less \
        npm \
        libsasl2-dev \
        build-essential \
        slapd \
        ldap-utils  \
        tox \
        lcov \
        valgrind \
        libldap2-dev \
        python3-dev \
        python3-magic \
        python3-num2words \
        python3-odf \
        python3-pdfminer \
        python3-pip \
        python3-phonenumbers \
        python3-pyldap \
        python3-qrcode \
        python3-renderpm \
        python3-setuptools \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        python3-cffi \
        python3-psycopg2 \
        python3-babel \
        python3-dateutil \
        python3-decorator \
        python3-docutils \
        python3-geoip2 \
        python3-gevent \
        python3-pil \
        python3-jinja2 \
        python3-libsass \
        python3-lxml \
        python3-ofxparse \
        python3-passlib \
        python3-polib \
        python3-psutil \
        python3-pydot \
        python3-openssl \
        python3-pypdf2 \
        python3-rjsmin \
        python3-reportlab \
        python3-requests \
        python3-serial \
        python3-stdnum \
        python3-tz \
        python3-usb \
        python3-werkzeug \
        python3-xlsxwriter \
        python3-zeep \
        xz-utils && \
    if [ -z "${TARGETARCH}" ]; then \
        TARGETARCH="$(dpkg --print-architecture)"; \
    fi; \
    WKHTMLTOPDF_ARCH=${TARGETARCH} && \
    case ${TARGETARCH} in \
    "amd64") WKHTMLTOPDF_ARCH=amd64 && WKHTMLTOPDF_SHA=967390a759707337b46d1c02452e2bb6b2dc6d59  ;; \
    "arm64")  WKHTMLTOPDF_SHA=90f6e69896d51ef77339d3f3a20f8582bdf496cc  ;; \
    "ppc64le" | "ppc64el") WKHTMLTOPDF_ARCH=ppc64el && WKHTMLTOPDF_SHA=5312d7d34a25b321282929df82e3574319aed25c  ;; \
    esac \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_${WKHTMLTOPDF_ARCH}.deb \
    && echo ${WKHTMLTOPDF_SHA} wkhtmltox.deb | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# install latest postgresql-client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jammy-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update  \
    && apt-get install --no-install-recommends -y postgresql-client \
    && rm -f /etc/apt/sources.list.d/pgdg.list \
    && rm -rf /var/lib/apt/lists/*

# Install rtlcss (on Debian buster)
RUN npm install -g rtlcss

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
COPY ./wait-for-psql.py /usr/local/bin/wait-for-psql.py

ARG USER_ID=1000
ARG GROUP_ID=1000

# Crea el directorio y los usuarios/grupos
RUN mkdir /var/lib/odoo && \
    groupadd -g $GROUP_ID odoo && \
    useradd -u $USER_ID -g odoo odoo -d /var/lib/odoo && \
    mkdir /data && \
    chown odoo:odoo /var/lib/odoo /data\
    && chmod +x /entrypoint.sh \
    && chmod +x /usr/local/bin/wait-for-psql.py


COPY ./requirements.txt /tmp/requirements.txt

RUN python3 -m pip install -r /tmp/requirements.txt && rm /tmp/requirements.txt

# Cambia al usuario odoo
#USER odoo


# Set permissions and Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons


RUN chown odoo /etc/odoo/odoo.conf \
    && mkdir -p /mnt/extra-addons \
    && chown -R odoo /mnt/extra-addons \
    && mkdir -p /opt/odoo17.0  \
    && chown -R odoo /opt/odoo17.0
#    && curl -o odoo_17.0.20240815.zip -sSL http://nightly.odoo.com/17.0/nightly/src/odoo_17.0.20240815.zip \
#    && unzip -q odoo_17.0.20240815.zip -d /opt/  \
#    && mv /opt/odoo-17.0.* /opt/odoo17.0  \
#    && rm -rf odoo_17.0.20240815.zip\


VOLUME ["/var/lib/odoo", "/mnt/extra-addons", "/opt/odoo17.0"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf


# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]