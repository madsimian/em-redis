em-redis
    by Jonathan Broad
    (http://www.relativepath.org)

== DESCRIPTION:

An Event Machine (http://rubyeventmachine.com/)-based library for interacting with the very cool Redis
(http://code.google.com/p/redis/) data store by Salvatore 'antirez' Sanfilippo.
Modeled after eventmachine's implementation of the memcached protocol, and
influenced by Ezra Zygmuntowicz's redis-rb library (distributed as part of
redis).

This library is only useful when used as part of an application that relies on
Event Machine's event loop.  It implements an EM-based client protocol, which
leverages the non-blocking nature of the EM interface to acheive significant
parallelization without threads.

WARNING: this library is my first attempt to write an evented client protocol,
and isn't currently used in production anywhere.  All that bit in the license
about not being warranted to work for any particular purpose really applies.


== FEATURES/PROBLEMS:

* Implements most Redis calls (see:
http://code.google.com/p/redis/wiki/CommandReference) with the notable
exception of MONITOR

== TODO:

* Right now method names are identical to Redis command names.  I'll add some nice aliases soon.
* I'm sure multibulk responses can be handled more elegantly 
* Better default error handling?  Provide a default response block?

== SYNOPSIS:

* Like any Deferrable eventmachine-based protocol implementation, using
EM-Redis involves making calls and passing blocks that serve as callbacks when
the call returns.  

  require 'em-redis'

  EM.run do
    redis = EM::Protocol::Redis.connect
    error_callback = lambda {|code| puts "Error code: #{code}" }
    redis.on_error error_callback
    redis.set "a", "foo" do |response|
      if r == 1 # success!
        redis.get "a" do |response|
          puts response
        end
      else
        puts "alrea
      end
    end
  end

== REQUIREMENTS:

* Redis (download from: http://code.google.com/p/redis/downloads/list)

== INSTALL:

* sudo gem install madsimian-em-redis --source http://gems.github.com

== LICENSE:

(The MIT License)

Copyright (c) 2008

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
