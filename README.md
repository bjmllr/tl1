# TL1

[![Gem Version](https://badge.fury.io/rb/tl1.svg)](https://rubygems.org/gems/tl1)
[![Build Status](https://travis-ci.org/bjmllr/tl1.svg)](https://travis-ci.org/bjmllr/tl1) 

The TL1 protocol is used by network operators to manage optical and other
networking equipment produced by multiple vendors. Although it is has a terse
and unusual command syntax, it was created with the intent of being useful for
interactive, command-line-like use.

This library offers a small set of utility classes intended for automating TL1
sessions. It was initially created in 2017 to interact with BTI 7200 devices,
but it aspires to be useful for anything that speaks TL1.

`tl1` is tested on Ruby 2.3 and 2.4 but probably works on anything newer than
2.0. It has no other formal dependencies, but to make it useful, you probably
need `Net::SSH::Telnet` (https://github.com/duke-automation/net-ssh-telnet), see
Connecting below.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tl1'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tl1

## Usage

### Connecting

The first step is to instantiate some sort of I/O object to handle the
lower-level communications with the target device. The TL1 protocol rides on top
of other networking protocols such as SSH or telnet, but `TL1` doesn't have any
methods to open a socket. Instead, you will probably want to use
`Net::SSH::Telnet` (or perhaps `Net::Telnet`) to establish an interactive
sesssion, and pass that object in to `TL1::Session.new`:

```ruby
require 'net/ssh/telnet'
require 'tl1'
ssh = Net::SSH::Telnet.new(
  'Host' => hostname,
  'Port' => port,
  'Username' => username,
  'Password' => password
)
tl1 = TL1::Session.new(ssh)
```

If you are (carefully!) using Telnet instead of SSH, you can substitute
`Net::Telnet` for `Net::SSH::Telnet`. If neither of those works for you, you can
try using any `IO` subclass (for example a pipe) in conjunction with `expect`
from the standard library, which adds an `#expect` method to `IO`. The only
methods needed on the object passed to `TL1::Session.new` are `#write` and
`#expect`.

If you need to log in, change modes, or take any other action to prime the
target device to speak TL1, outside of the TL1 protocol, do that before calling
`TL1::Session.new`. `ACT-USER`, `CANC-USER`, and other session management
actions that occur within the TL1 protocol should be done via the
`TL1::Session`.

### Commands

In `tl1`, commands are objects that define a format for constructing an input
message (the "command") and a format for reading an output message (the
"response"). The syntax of the format string is intended to be close to the
documentation supplied by the vendor.

A handful of sample commands for the BTI 7200 platform are defined in
`tl1/platforms/bti.rb`.

A new command can be defined using `TL1::Command.new`:

```ruby
RTRV_EQPT = TL1::Command.new(
  'RTRV-EQPT',
  '<aid>:<type>:ID=<id>,C1=<custom1>,C2=<custom2>,C3=<custom3>:<pst>,<sst>'
)
tl1.cmd(RTRV_EQPT)
```

The first argument to `TL1::Command.new` is an input message format: in its
simplest form, a command string to be sent to the target device.

The second argument to `TL1::Command.new` is an output message format. Records
in the output message are extracted and converted into hashes according to the
format string. Records are divided into fields, which are separated by colons,
may be further separated by commas, and if separated by commas, may be labeled
with a keyword. If the second argument is omitted (or `nil`), the raw output for
that command will be returned as a string, with no parsing.

Examples of each type of field are given above. `aid` and `type` are simple
strings. `id`, `custom1`, `custom2`, and `custom3` are keyword-labeled strings
sharing a single field, and separated by commas within that field. `pst` and
`sst` are strings sharing a single field and separated by commas within that
field.

When `TL1::Session#cmd` is called with a `TL1::Command` argument, the command's
defined input message is sent to the session's underlying IO, and the received
output message is processed according to the output format string.

An output message for the `RTRV_EQPT` command might look like this:

```
   bti7200hoge 17-08-31 16:29:53
M  100 COMPLD
   "MS-1:BT7A51AR::IS-NR,"
   "D40MD-0-2:BT7A37AA::,"
;
BTI7000>
```

And then the returned array of records for that output message will look like
this:

```ruby
[
  { aid: 'MS-1', type: 'BT7A51AR', pst: 'IS-NR', sst: '' },
  { aid: 'D40MD-0-2', type: 'BT7A37AA', pst: '', sst: '' }
]
```

Note that the keyword-labeled fields are missing (because their keywords are
missing), while other fields that are empty are present and represented as empty
strings.

Some commands will accept arguments. For example, a more complete implementation
of `RTRV_EQPT` will accept an `aid` to narrow the query:

```ruby
RTRV_EQPT = TL1::Command.new(
  'RTRV-EQPT:<tid>:<aid>:<ctag>',
  '<aid>:<type>:ID=<id>,C1=<custom1>,C2=<custom2>,C3=<custom3>:<pst>,<sst>'
)
tl1.cmd(RTRV_EQPT, aid: 'MS-1')
# => [{ aid: 'MS-1', type: 'BT7A51AR', pst: 'IS-NR', sst: '' }]
```

The input and output format strings have the same syntax. Items in angle
brackets are optional variables, unbracketed text is literal. It's common for
vendors to specify a field as "mandatory" or "optional", but we don't make any
attempt to distinguish between them here; in effect, all fields are treated as
optional.

Most fields will be variables, but occasionally there will be a literal field.
In the following command definition, the first field of the output format is a
literal representing the empty string (`""`), and the last field is a literal
representing the string `"asdf"`:

```ruby
RTRV_ROUTE_CONN = Command.new(
  'RTRV-ROUTE-CONN',
  ':<ipaddr>,<mask>,<nexthop>:COST=<cost>,ADMINDIST=<admindist>:asdf'
)
```

Literals don't affect the output of parsing, but they will raise an exception if
the output message has text in that field that does not exactly match the
literal. In the above command definition, all output records are required to
start with `":"` and end with `":asdf"`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/bjmllr/tl1 . This project is intended to be a safe, welcoming
space for collaboration, and contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

Please include tests with any pull request. If you need help with testing,
please open an issue.

## License

The gem is available as open source under the terms of the [GNU General Public
License version 3](http://opensource.org/licenses/GPL-3.0).
