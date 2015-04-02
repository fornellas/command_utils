# command_utils

Simple Gem to assist running external commands an processing its outputs.

This Gem will help you call external commands, process its stdout and stderr, to your own fit, and at the end, validate its return code.

# Example

## Processing output

```ruby
require 'command_utils'

puts 'Execute command and send output to block:'
command = 'echo -n stdout message ; echo -n stderr message 1>&2'
CommandUtils.each_output(command) do |stream, data|
  puts "#{stream}: #{data}"
end
puts

puts 'Execute command and send output to given logger instance:'
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
puts

puts 'Raises if command does not return 0:'
command = 'echo -n stdout message ; echo -n stderr message 1>&2 ; exit 3'
begin
  CommandUtils.each_output(command) do |stream, data|
    puts "#{stream}: #{data}"
  end
rescue
  $stderr.puts "Raised #{$!.class}: #{$!}"
end

```

This should output something like:
```
Execute command and send output to block:
stdout: stdout message
stderr: stderr message

Execute command and send output to given logger instance:
I, [2015-04-02T09:47:13.083966 #17466]  INFO -- : This was output to stdout: stdout message
E, [2015-04-02T09:47:13.084226 #17466] ERROR -- : This was output to stderr: stderr message

Raises if command does not return 0:
stdout: stdout message
stderr: stderr message
Raised CommandUtils::NonZeroStatus: Command exited with 3.
```
