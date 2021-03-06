To run the frontend api use need first to install and migrate the backend api: https://github.com/AfeefaDe/afeefa-backend-api as it migrates and sets up the database the frontend uses.

1. Clone respository
2. Add your custom `config/database.yml` (copy from `config/database.yml.example`)
3. run `bundle install`
4. `rails s` or `rails s -p 3001` or `rails s -b 10.0.3.130 -p 3001`
5. There is only 1 endpoint: `http://localhost:3001/entries`

## Running die Api

`rails s` or `rails s -p 3001` or `rails s -b 10.0.3.130 -p 3001`

## Remote Debugging

On server and client both install:

* `gem install ruby-debug-ide`
* `gem install debase`

Then start the remote server like this:

`rdebug-ide --port 1236 --dispatcher-port 26166 --host 0.0.0.0 -- bin/rails s -b 10.0.3.130 -p 3001`

Attach your local IDE debugger. VSCode example config:

```
    {
      "name": "Listen for rdebug-ide",
      "type": "Ruby",
      "request": "attach",
      "cwd": "${workspaceRoot}",
      "remoteHost": "backend.afeefa.dev",
      "remotePort": "1236",
      "remoteWorkspaceRoot": "/afeefa/fapi"
    }
```

## Maintenance Tasks

To be called locally 'on my machine' and run remotely:

*build dev|production JSON data file cache*
This command entirely rebuilds the data cached for use in frontend.
Runs automatically after each deployment.

`cap [dev|production] cache:build_all`

## Testing

```
bundle exec rails db:environment:set RAILS_ENV=test test

bundle exec rails test -n EntriesControllerTest#test_should_raise_not_found_if_orga_has_no_contact_data
```
