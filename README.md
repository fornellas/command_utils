# command_utils

[![Build Status](https://travis-ci.org/fornellas/command_utils.svg?branch=master)](https://travis-ci.org/fornellas/command_utils)
[![Inline docs](http://inch-ci.org/github/fornellas/command_utils.svg?branch=master)](http://inch-ci.org/github/fornellas/command_utils)
[![Gem Version](https://badge.fury.io/rb/command_utils.svg)](http://badge.fury.io/rb/command_utils)
[![GitHub issues](https://img.shields.io/github/issues/fornellas/command_utils.svg)](https://github.com/fornellas/command_utils/issues)
[![GitHub license](https://img.shields.io/badge/license-GPLv3-blue.svg)](https://raw.githubusercontent.com/fornellas/command_utils/master/LICENSE)
[![Downloads](http://ruby-gem-downloads-badge.herokuapp.com/command_utils?type=total)](https://rubygems.org/gems/command_utils)

* Home: https://github.com/fornellas/command_utils/
* RubyGems.org: https://rubygems.org/gems/command_utils
* Documentation: http://www.rubydoc.info/gems/command_utils/
* Bugs: https://github.com/fornellas/command_utils/issues

## Description

This gem provides a simple interface to execute external commands. You can capture both stdout / stderr, process it, and be safe that if command has not exited with 0, you will get an exception.

## Install

    gem install command_utils

This gem uses [Semantic Versioning](http://semver.org/), so you should add to your .gemspec something like:
```ruby
  s.add_runtime_dependency 'command_utils', '~> 0.4', '>= 0.4.1'
```

## Examples

First, require it:
```ruby
require 'command_utils'
```

### Read each line

```ruby
command = 'echo -n stdout message ; echo -n stderr message 1>&2'
CommandUtils.each_line(command) do |stream, data|
  puts "#{stream}: #{data}"
end
```

### Send output to logger

```ruby
require 'logger'
command = 'echo -n stdout message ; echo -n stderr message 1>&2'
CommandUtils.logger_exec(
  command,
  logger: Logger.new(STDOUT),
  stdout_level: :info,
  stderr_level: :error,
  stdout_prefix: 'This was output to stdout: ',
  stderr_prefix: 'This was output to stderr: ',
  )
```

### Raises unless 0 exit

```ruby
command = 'echo -n stdout message ; echo -n stderr message 1>&2 ; exit 3'
begin
  CommandUtils.each_output(command) do |stream, data|
    puts "#{stream}: #{data}"
  end
rescue
  $stderr.puts "Raised #{$!.class}: #{$!}"
end
```
