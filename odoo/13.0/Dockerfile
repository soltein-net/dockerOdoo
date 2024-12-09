FROM ubuntu:jammy

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]
# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG en_US.UTF-8
# Retrieve the target architecture to install the correct wkhtmltopdf package
ARG TARGETARCH

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        wget \
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
        python3.10-venv \
        adduser \
        lsb-base \
        zlib1g-dev \
        libncurses5-dev \
        libgdbm-dev \
        libnss3-dev \
        libreadline-dev \
        libffi-dev \
        libsqlite3-dev \
        libbz2-dev \
        libxml2-dev \
        libxslt1-dev \
        libpq-dev \
        node-less \
        npm \
        git \
        python3-pip \
        python3-venv \
        python3-psycopg2 \
        postgresql-client && \
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

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG GROUP_ID=1000


# instala python 3.8
WORKDIR /tmp
RUN wget https://www.python.org/ftp/python/3.8.20/Python-3.8.20.tgz \
    && tar xzf Python-3.8.20.tgz \
    && cd Python-3.8.20 \
    && ./configure --enable-optimizations \
    && make altinstall \
    && cd .. \
    && rm -rf Python-3.8.20 Python-3.8.20.tgz

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/odoo13.conf
COPY ./wait-for-psql.py /usr/local/bin/wait-for-psql.py

# Crea el directorio y los usuarios/grupos
RUN mkdir /var/lib/odoo && \
    groupadd -g $GROUP_ID odoo && \
    useradd -u $USER_ID -g odoo odoo -d /var/lib/odoo && \
    mkdir /data && \
    chown odoo:odoo /var/lib/odoo /data\
    && chmod +x /entrypoint.sh \
    && chmod +x /usr/local/bin/wait-for-psql.py

RUN chown odoo /etc/odoo/odoo13.conf \
    && mkdir -p /mnt/extra-addons \
    && chown -R odoo /mnt/extra-addons \
    && mkdir -p /opt/odoo13.0  \
    && chown -R odoo /opt/odoo13.0


RUN pip install Cython==0.29.24

RUN python3.8 -m venv /opt/venv
RUN chown -R odoo /opt/venv

ENV PATH "/opt/venv/bin:$PATH"
ENV VIRTUAL_ENV "/opt/venv"
COPY ./requirements.txt /tmp/requirements.txt
RUN grep -v "lxml" /tmp/requirements.txt > /tmp/requirements_without_lxml.txt

RUN pip install setuptools==57.5.0 wheel==0.41.2 \
    && pip install -r /tmp/requirements_without_lxml.txt \
    && rm /tmp/requirements_without_lxml.txt

ENV CFLAGS="-DXML_POOR_ENTROPY=1"
RUN pip install lxml==4.6.5

#    && curl -o odoo_17.0.20240815.zip -sSL http://nightly.odoo.com/17.0/nightly/src/odoo_17.0.20240815.zip \
#    && unzip -q odoo_17.0.20240815.zip -d /opt/  \
#    && mv /opt/odoo-17.0.* /opt/odoo17.0  \
#    && rm -rf odoo_17.0.20240815.zip\


VOLUME ["/var/lib/odoo", "/mnt/extra-addons", "/opt/odoo13.0"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo13.conf


# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
