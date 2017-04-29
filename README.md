To run the frontend api use need first to install and migrate the backend api: https://github.com/AfeefaDe/afeefa-backend-api as it migrates and sets up the database the frontend uses.

1. Clone respository
2. Add your custom `config/database.yml` (copy from `config/database.yml.example`)
3. run `bundle install`
4. `rails s -p 3001`
5. There is only 1 endpoint: `http://localhost:3001/entries`
