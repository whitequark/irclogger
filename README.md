irclogger
=========

irclogger is a simple irc logger with a fluid web interface, search function, and a live streaming mode where new messages automatically appear in today's log.

Requirements
------------

  * A Linux server. Non-Linux setups will probably work, but have never been tested.
  * Ruby  >= 1.9.3
  * MySQL >= 5 or PostgreSQL >= 9.3
  * Redis >= 2.7
  * Nginx

The default launch scripts assume that Ruby is managed with RVM, but you can remove the two lines mentioning RVM if you are using some other solution or just system Ruby.

Installation
------------

  1. Make sure all dependencies are installed and configured.
  2. Create a MySQL database and import the schema from `config/sql/mysql-schema.sql`, or, create a PostgreSQL database and import the schema from `config/sql/postgresql-schema.sql`.
  3. Copy `config/application.yml.example` to `config/application.yml`.
  4. Edit `config/application.yml`. The fields should be self-documenting.
  5. Edit `config/thin.yml` if you want to place the socket somewhere else than `/tmp/irclogger.sock`.
  6. Copy `config/nginx.conf.example` to `/etc/nginx/sites-enabled/irclogger`. Edit the `server_name` and `root` directives to match your setup. Edit the `upstream` directive if you have changed socket location.
  7. Add the following lines to your crontab:

         @reboot (cd /var/www/irclogger && ./launch-viewer.sh)
         @reboot (cd /var/www/irclogger && ./launch-logger.sh)

     Replace /var/www/irclogger with the appropriate installation path.

  8. Reload nginx confguration.
  9. Reboot. (Joking.) `cd /var/www/ircloggger; bundle && ./launch-viewer.sh && ./launch-logger.sh`.

Updating configuration
----------------------

  1. Edit `config/application.yml`.
  2. `./deploy-logger.sh`

FAQ
---

### Messages appear multiple times in the log

Use the `./deploy-logger.sh` script for starting or restarting the logger. If an instance of it is already active, it will be killed by the script.

### The channel list does not appear in the sidebar

The channel list only appears on the domain that matches the "domain" field in application.yml. This is done to allow pointing other domains to the main one via CNAME, e.g. see [logs.jruby.org](http://logs.jruby.org/jruby).

Upgrading
---------

  1. `git pull`
  2. Read the git log. I will mention if the updates change the schema, include breaking changes, etc.
  3. `./deploy-logger.sh && ./deploy-viewer.sh`
