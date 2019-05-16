# Updating your instance
- Log into `pleroma` user and make sure `MIX_ENV` is set like it should be.
- go to the instance directory: `cd ~pleroma/pleroma`
- Pull the latest changes: `git pull`
- Pull any new dependencies: `mix deps.get`
- Stop the pleroma service: `service pleroma stop`
- Run any new migrations: `mix ecto.migrate`
- Start the pleroma service back: `service pleroma start`
