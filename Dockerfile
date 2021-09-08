FROM php:8.0.9-fpm

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  git \
  libicu-dev \
  libfreetype6-dev \
  libjpeg62-turbo-dev \
  librabbitmq-dev \
  libpng-dev \
  libpq-dev \
  libxslt-dev \
  libzip-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j$(nproc) \
  gd \
  intl \
  pdo_pgsql \
  xsl \
  zip

# https://github.com/php-amqp/php-amqp/issues/386#issuecomment-754184017
RUN docker-php-source extract \
  && mkdir /usr/src/php/ext/amqp \
  && curl -L https://github.com/php-amqp/php-amqp/archive/master.tar.gz | tar -xzC /usr/src/php/ext/amqp --strip-components=1 \
  && docker-php-ext-install -j$(nproc) amqp \
  && docker-php-source delete

RUN pecl install \
  redis \
  && docker-php-ext-enable redis

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  && php -r "if (hash_file('sha384', 'composer-setup.php') === '756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
  && php composer-setup.php \
  && php -r "unlink('composer-setup.php');" \
  && mv composer.phar /usr/local/bin/composer

RUN curl -sS https://get.symfony.com/cli/installer | bash \
  && mv /root/.symfony/bin/symfony /usr/local/bin/symfony

RUN symfony server:ca:install

# https://docs.docker.com/engine/install/debian/
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# https://docs.docker.com/compose/install/
RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

# https://github.com/nodesource/distributions/blob/master/README.md#debinstall
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  nodejs \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# https://classic.yarnpkg.com/en/docs/install#debian-stable
RUN npm install --global yarn

RUN mkdir /src
WORKDIR /src
