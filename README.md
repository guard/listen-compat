# Listen::Compat

A wrapper for [Listen](https://github.com/guard/listen) to "guarantee" a
simplified and unchanging (future-compatible) API for cross-platform watching
files and directories.

It is designed to work with any version of Listen installed (it contains
workarounds for buggy or incomplete old versions).

This is useful for app/gem developers who want to "just watch files until
Ctrl-C". (And not care about historical incompatibilities or bug fixes /
regressions related to Listen).

It also helps easily write unit tests for using listen in other apps, without
having to deal with threads, locks, queues, sleeping, Listen API changes, etc.

## Installation

As long as users of you application have *any* version of Listen installed,
listen-compat should work.

Example Gemfile:

```ruby
gem 'listen-compat'
gem 'listen' # hopefully, any version you like will work
```

## Usage

You can assume the following interface will never change.


```ruby
require 'listen/compat/wrapper'

listener = Listen::Compat::Wrapper.create

directories = %w(foo bar baz)
options = { force_polling: false }

listener.listen(directories, options) do |modified, added, removed|
  puts "Modified: #{modified.inspect}"
  puts "Added: #{added.inspect}"
  puts "Removed: #{removed.inspect}"
end
```

(You can assume compatibility will become better and more robust without having
to make any changes in your app's code.)


## Details

This will always be guaranteed to include everything necessary:

```ruby
require 'listen/compat/wrapper'
```

The following will do whatever magic necessary to find a usable version of
Listen, require it, and return the right wrapper.


```ruby
listener = Listen::Compat::Wrapper.create
```

You can assume directories can be passed in any form (relative, absolute,
    Pathname, real-only directories) and any encoding and this gem's
responsibility is to deal with it.

```ruby
directories = %w(foo bar baz)
```

While different version of listen support different options, it's
Listen-Compat's responsibility to make sure they are properly translated or
ignored, and possible to set without changes in your code (e.g. environment
    variables, listen config files, etc.)

```ruby
options = { force_polling: false }
```

You can assume your callback will always receive an array of 3 arrays:
- possibly changed files (but maybe no longer existing)
- possibly added files (but maybe no longer existing)
- possibly removed files (but may be existing again)


```ruby
listener.listen(directories, options) do |modified, added, removed|
```

## Unit testing Listen in you app

Listen-compat provides a fast-enough and thorough enough test helper for you to
just add a single unit test to accurately simulate a real blocking session with
Listen.

It also lets you conveniently use relative files for simulating events (even
though the actual Listen implementation reports full paths).


```ruby
require "listen/compat/test/session"

def test_if_watching_files_works

  session = Listen::Compat::Test::Session.new do
    # put whatever code would cause Listen to block here:
    myapp.start_listening_for_changes
  end

  # simulate changes
  session.simulate_events(["foo.png"], [], [])

  # simulate the user stopping the listening with Ctrl-C
  session.interrupt

  # whatever tests to make you app's callback was called:
  assert_equal(%w(foo.png), myapp.updated_files_or_something)
end
```

## Summary

By using the above interface and the single using test above, you shouldn't
have to care about anything else related about how Listen works with your app.


## Contributing

1. Fork it ( https://github.com/[my-github-username]/listen-compat/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
