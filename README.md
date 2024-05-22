# ERAS
Enhanced Running Average Stats Service

Zooniverse's Stats Service Measuring Volunteer Effort and Contribution.

## Full Documentation

See the [Documentation Site](https://zooniverse.github.io/eras) or our [Wiki](https://github.com/zooniverse/eras/wiki) for full documentation, examples, operational details and other information

## Running App Locally With Docker
```
docker-compose build
docker-compose run --rm eras bundle install
docker-compose run --rm eras rails db:create
docker-compose run --rm eras rails db:migrate
docker-compose up
```

If running into errors of missing tables/continuous aggregates run the following:
```
docker-compose run --rm eras rake db:setup:development
```

### Running Specs Locally
```
docker-compose run  --rm -e RAILS_ENV=test eras bundle exec rspec
```
