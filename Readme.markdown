Markdown Journal
================

An online journal which saves short, tweet like entries into Markdown documents inside of your Dropbox.

Requirements
------------

### Runtime Requirements

* Ruby
* Ruby Gems
* Sinatra

### Development Time Requirements

* Node.js
* Bower

### User Requirements

* Dropbox account to store the journal

Config
------

Create a file `config.yml` in the root dir of the project. Inside you should have:

    key: your-dropbox-app-key-string
    secret: your-dropbox-app-secret-string
    url: http://localhost:4567/write
