Gem::Specification.new do |s|
  s.name = %q{em-redis}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jonathan Broad"]
  s.date = %q{2009-04-28}
  s.description = %q{An EventMachine[http://rubyeventmachine.com/] based library for interacting with the very cool Redis[http://code.google.com/p/redis/] data store by Salvatore 'antirez' Sanfilippo. Modeled after eventmachine's implementation of the memcached protocol, and influenced by Ezra Zygmuntowicz's {redis-rb}[http://github.com/ezmobius/redis-rb/tree/master] library (distributed as part of Redis).  This library is only useful when used as part of an application that relies on Event Machine's event loop.  It implements an EM-based client protocol, which leverages the non-blocking nature of the EM interface to acheive significant parallelization without threads.  WARNING: this library is my first attempt to write an evented client protocol, and isn't currently used in production anywhere.  All that bit in the license about not being warranted to work for any particular purpose really applies.}
  s.email = %q{jonathan@relativepath.org}
  s.extra_rdoc_files = ["History.txt", "README.rdoc"]
  s.files = ["History.txt", "Manifest.txt", "README.rdoc", "em-redis.gemspec", "Rakefile", "lib/em-redis.rb", "lib/em-redis/redis_protocol.rb", "spec/test_helper.rb", "spec/live_redis_protocol_spec.rb", "spec/redis_protocol_spec.rb"]
  s.has_rdoc = true
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{em-redis}
  s.rubygems_version = %q{1.3.0}
  s.summary = %q{An EventMachine[http://rubyeventmachine}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<bacon>, [">= 0"])
      s.add_development_dependency(%q<bones>, [">= 2.1.1"])
    else
      s.add_dependency(%q<bacon>, [">= 0"])
      s.add_dependency(%q<bones>, [">= 2.1.1"])
    end
  else
    s.add_dependency(%q<bacon>, [">= 0"])
    s.add_dependency(%q<bones>, [">= 2.1.1"])
  end
end

