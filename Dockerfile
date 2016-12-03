FROM knowledgearcdotorg/base

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

ENV PG_VERSION 9.5

RUN apt-get update && \
    apt-get -qy --fix-missing --force-yes install language-pack-en && \
    update-locale LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8

RUN dpkg-reconfigure locales

RUN apt-get install -y postgresql && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/postgresql && chown -R postgres /var/run/postgresql

RUN ln -s /usr/lib/postgresql/$PG_VERSION/bin/postgres /usr/bin/postgres

# set up postgresql config and data dirs like every other service.
RUN rm -Rf /var/lib/postgresql/*
RUN mv /etc/postgresql/$PG_VERSION/main/* /etc/postgresql/
RUN rm -Rf /etc/postgresql/$PG_VERSION

ENV PGDATA /var/lib/postgresql
VOLUME /var/lib/postgresql

RUN sed \
    -i.orig \
    -e s/\\\/$PG_VERSION\\\/main//g \
    -e s/#listen_addresses\\\s=\\\s\'localhost\'/listen_addresses\ =\ \'*\'/g \
    /etc/postgresql/postgresql.conf

RUN echo 'host\tall\tall\t0.0.0.0/0\tmd5' >> /etc/postgresql/pg_hba.conf

COPY supervisord/postgresql.conf /etc/supervisor/conf.d/postgresql.conf

COPY entrypoint.sh /usr/local/bin/
RUN chmod 750 /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

EXPOSE 5432

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
