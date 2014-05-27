# Datamine

A grab bag of utilities for interacting with various ticketing and task tracking systems.

__WARNING:__ The stuff in here was mostly hacked together over short spans of time to accomplish pressing tasks.
Code orginization and quality is horrible.
If you use this it may do something neat, or it may eat your data.

## Installation Steps

Installing through Bundler is recommended:

    bundle install --path=.bundler/lib

## Example Usage

The following runs a query against the PuppetLabs issue tracker that returns all issues in the PUP, FACT and HI projects that have been updated since the day started:

    bundle exec datamine jira --url tickets.puppetlabs.com query \
      'project IN (PUP,FACT,HI) AND updatedDate > startOfDay()'
