To run the frontend api use need first to install and migrate the backend api: https://github.com/AfeefaDe/afeefa-backend-api as it migrates and sets up the database the frontend uses.

1. Clone respository
2. Add your custom `config/database.yml` (copy from `config/database.yml.example`)
3. run `bundle install`
4. `rails s -p 3001`
5. There is only 1 endpoint: `http://localhost:3001/entries`

## Remote Debugging

On server and client both install:

* `gem install ruby-debug-ide`
* `gem install debase`

Then start the remote server like this:

`rdebug-ide --port 1236 --dispatcher-port 26166 --host 0.0.0.0 -- bin/rails server -b 10.0.3.130 -p 3001`

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