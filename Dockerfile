FROM ubuntu:14.04.2

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# Ruby settings
ENV RUBY_MAJOR 2.2
ENV RUBY_VERSION 2.2.3
ENV RUBY_DOWNLOAD_SHA256 df795f2f99860745a416092a4004b016ccf77e8b82dec956b120f18bdc71edce
ENV RUBYGEMS_VERSION 2.4.8

# set apt source to mirrors.163.com
# see http://mirrors.163.com/.help/ubuntu.html
ADD ./sources.list.trusty /etc/apt/sources.list

# update system and install some packages
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y \
    curl \
    autoconf \
    make \
    bison \
    build-essential \
    libssl-dev \
    libyaml-dev \
    libreadline6-dev \
    zlib1g-dev \
    libncurses5-dev \
    libffi-dev \
    libgdbm3 \
    libgdbm-dev \
    libqtwebkit-dev \
    qt4-qmake

# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
RUN apt-get install -y ruby
RUN mkdir -p /usr/src/ruby \
    && curl -fSL -o ruby.tar.gz "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" \
    && echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c - \
    && tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1 \
    && rm ruby.tar.gz
RUN cd /usr/src/ruby \
    && autoconf \
    && ./configure --disable-install-doc \
    && make -j"$(nproc)" \
    && make install \
    && apt-get purge -y --auto-remove bison libgdbm-dev ruby \
    && gem update --system $RUBYGEMS_VERSION \
    && rm -rf /usr/src/ruby

# install things globally, for great justice
ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH

ENV BUNDLER_VERSION 1.10.6

RUN gem install bundler --version "$BUNDLER_VERSION" \
    && bundle config --global path "$GEM_HOME" \
    && bundle config --global bin "$GEM_HOME/bin"

# don't create ".bundle" in all our apps
ENV BUNDLE_APP_CONFIG $GEM_HOME

ADD ./Gemfile /usr/src/Gemfile
RUN bundler install \
    --gemfile /usr/src/Gemfile \
    --clean

# cleanup
RUN apt-get autoremove -y && \
  apt-get clean && \
  apt-get autoclean && \
  rm -rf /usr/share/man/?? && \
  rm -rf /usr/share/man/??_* && \
  rm -rf /var/lib/apt/lists/* && \
  echo -n > /var/lib/apt/extended_states && \
  rm -rf /tmp/* /var/tmp/*

# Define mount points.
VOLUME ["/data"]

# Define working directory.
WORKDIR /data

CMD ["/bin/bash"]
