# command_utils

Simple Gem to assist running external commands an processing its outputs.

This Gem will help you call external commands, process its stdout and stderr, to your own fit, and at the end, validate its return code.

# Example

## Processing output

```ruby
require 'command_utils'

c = CommandUtils.new('echo -n stdout message ; echo -n stderr message 1>&2')

# exec and process output
c.each_output do |stream, data|
  puts "#{stream}: #{data}"
end

# exec and log output
require 'logger'
c.logger_exec(
  logger: Logger.new(STDOUT),
  stdout_level: :info,
  stderr_level: :error,
  )
```

This should output something like:
```
stdout: stdout message
stderr: stderr message
I, [2015-04-02T02:02:50.140413 #23752]  INFO -- : stdout message
E, [2015-04-02T02:02:50.140550 #23752] ERROR -- : stderr message
```
