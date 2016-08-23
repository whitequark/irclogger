irclogger
=========

irclogger is a simple irc logger with a fluid web interface, search function, and a live streaming mode where new messages automatically appear in today's log.

Requirements
------------

  * A Debian-based system (any other *nix can be used, but init scripts are written for Debian)
  * Ruby  >= 1.9.3
  * MySQL >= 5 or PostgreSQL >= 9.3
  * Redis >= 2.7
  * Nginx

Installation
------------

  1. Make sure all dependencies are installed and configured.
  2. Create a MySQL database and import the schema from `config/sql/mysql-schema.sql`, or, create a PostgreSQL database and import the schema from `config/sql/postgresql-schema.sql`.
  3. Run `bundle install --deployment --without postgresql` if you use MySQL, or `bundle install --deployment --without mysql` if you use PostgreSQL.
  3. Copy `config/application.yml.example` to `config/application.yml`.
  4. Edit `config/application.yml`. The fields should be self-documenting.
  6. Copy `config/nginx.conf.example` to `/etc/nginx/sites-enabled/irclogger`. Edit the `server_name`, `root` and `upstream` directives to match your setup.
  7. Copy `config/init.d/*` to `/etc/init.d/*`. Edit the `ROOT` and `START_ARGS` fields to match your setup.
  8. Run `update-rc.d irclogger-logger defaults && update-rc.d irclogger-viewer defaults`.
  8. Reload nginx confguration.
  9. Start logger and viewer with `service irclogger-logger start && service irclogger-viewer start`.

Updating configuration
----------------------

  1. Edit `config/application.yml`.
  2. Restart logger with `service irclogger-logger restart`.

FAQ
---

### Messages appear multiple times in the log

Make sure that whatever method you use for restarting the logger does not leave old instances around.

### The channel list does not appear in the sidebar

The channel list only appears on the domain that matches the "domain" field in application.yml. This is done to allow pointing other domains to the main one via CNAME, e.g. see [logs.jruby.org](http://logs.jruby.org/jruby).

Upgrading
---------

  1. `git pull`
  2. Read the git log. I will mention if the updates change the schema, include breaking changes, etc.
  3. See step 3 of Installation above.
  3. Restart logger and viewer with `service irclogger-logger restart && service irclogger-viewer restart`.
