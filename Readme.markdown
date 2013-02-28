Markdown Journal
================

An online journal which saves short, tweet like entries into Markdown documents inside of your Dropbox. You can see it in action at [markdownjournal.com][mj].

Requirements
------------

### Runtime Requirements

* [Ruby][rb]
* [Ruby Gems][gm]
* [Sinatra][sn]
* [Dropbox SDK][db]

### Development Time Requirements

* [Node.js][no]
* [Bower][bo]

### User Requirements

* [Dropbox][dx] account to store the journal

Config
------

Create a file `config.yml` in the root directory of the project. Inside you should have:

    key: your-dropbox-app-key-string
    secret: your-dropbox-app-secret-string
    url: http://localhost:4567/write

Go to the `public` directory and run:

    bower install

This will fetch Twitter Bootstrap and jQuery into the `public/components` directory. Now you should be all set.

Licensing
---

Markdown Journal is licensed under [GPLv3][gp].

[mj]: http://markdownjournal.com
[rb]: http://rubylang.org
[gm]: http://rubygems.org/
[sn]: http://www.sinatrarb.com/
[dx]: http://www.dropbox.com
[db]: https://www.dropbox.com/developers/core/setup#ruby
[no]: http://nodejs.org/
[bo]: http://twitter.github.com/bower/
[gp]: http://www.gnu.org/licenses/gpl-3.0-standalone.html
