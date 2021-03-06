Markdown Journal
================

An online journal which saves short, tweet like entries into Markdown documents inside of your Dropbox. You can see it in action at [markdownjournal.com][mj].

Requirements
------------

### System Requirements

* [Ruby][rb]
* [Ruby Gems][gm]
* [Bundler][bu]

### Runtime Gem Dependencies

Gem dependencies are now managed by [Bundler][bu]. To download and install all the required gems automatically run the following in the project folder:

    bundle install

In case you are interested, here is the list of gems that are being installed:

* [Sinatra Gem][sn]
* [Active Support Gem][as]
* [Dropbox API Gem][db]
* [TZInfo Library][tz]

### Development Time Requirements

These are optional, but make your life easier. I have not included the Twitter Boostrap or jQuery files with this project. Instead the `public` directory contains a `component.json` file with list of dependencies. This file is used by bower to fetch the required files. To use it you will need:

* [Node.js][no]
* [Bower][bo]

### User Requirements

* [Dropbox][dx] account to store the journal

Config
------

You will need a Dropbox API key. You can [register one here][rg]. Once you have *App key* and *App secret* values you will need to create a configuration file for your application.

Create a file `config.yml` in the root directory of the project. Inside you should have:

    key: your-dropbox-app-key-string
    secret: your-dropbox-app-secret-string
    url: http://localhost:4567/write

Go to the `public` directory and run:

    bower install

This will fetch Twitter Bootstrap and jQuery into the `public/components` directory. Now you should be all set.

Make sure you have `sinatra`, `dropbox_api` and other gems installed:

    gem install bundler
    bundle install

You can run the application locally like this:

    ruby app.rb

On older versions of ruby you may need to use:

    ruby -rubygems app.rb

This will run a server at `http://localhost:4567`.

Known Issues
------------

If you run into parsing errors when reading user YAML files, uncomment the following line in the code:

    YAML::ENGINE.yamler= 'syck'

In the newer versions of Ruby the default YAML parser sometimes throws a fit when reading files that have weird line endings or other artifacts. The Syck parser seems to work fine most of the time.
    

Licensing
---

Markdown Journal is licensed under [GPLv3][gp].

[bu]: http://gembundler.com/
[mj]: http://markdownjournal.com
[rb]: http://ruby-lang.org
[gm]: http://rubygems.org/
[sn]: http://www.sinatrarb.com/
[dx]: http://www.dropbox.com
[db]: https://github.com/Jesus/dropbox_api
[as]: http://rubygems.org/gems/activesupport
[no]: http://nodejs.org/
[bo]: http://twitter.github.com/bower/
[gp]: http://www.gnu.org/licenses/gpl-3.0-standalone.html
[tz]: http://tzinfo.rubyforge.org/

[rg]: https://www.dropbox.com/developers/apps
