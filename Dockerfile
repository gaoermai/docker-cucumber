FROM ruby:2.2.3

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y libqtwebkit-dev qt4-qmake

RUN gem install \
    bundler \
    cucumber \
    rspec \
    capybara \
    capybara-screenshot \
    capybara-webkit \
    selenium-webdriver

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

CMD ["cucumber"]
