# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{em-redis}
  s.version = "0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jonathan Broad"]
  s.date = %q{2009-12-15}
  s.description = %q{An EventMachine[http://rubyeventmachine.com/] based library for interacting with the very cool Redis[http://code.google.com/p/redis/] data store by Salvatore 'antirez' Sanfilippo.
Modeled after eventmachine's implementation of the memcached protocol, and influenced by Ezra Zygmuntowicz's {redis-rb}[http://github.com/ezmobius/redis-rb/tree/master] library (distributed as part of Redis).

This library is only useful when used as part of an application that relies on
Event Machine's event loop.  It implements an EM-based client protocol, which
leverages the non-blocking nature of the EM interface to achieve significant
parallelization without threads.}
  s.email = %q{jonathan@relativepath.org}
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.rdoc"]
  s.files = [".gitignore", "History.txt", "Manifest.txt", "README.rdoc", "Rakefile", "em-redis.gemspec", "lib/em-redis.rb", "lib/em-redis/redis_protocol.rb", "spec/live_redis_protocol_spec.rb", "spec/redis_protocol_spec.rb", "spec/test_helper.rb", "tasks/em-redis.rake"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{em-redis}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{An EventMachine[http://rubyeventmachine}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<eventmachine>, [">= 0.12.10"])
      s.add_development_dependency(%q<bacon>, [">= 1.1.0"])
      s.add_development_dependency(%q<em-spec>, [">= 0.2.0"])
      s.add_development_dependency(%q<bones>, [">= 3.2.0"])
    else
      s.add_dependency(%q<eventmachine>, [">= 0.12.10"])
      s.add_dependency(%q<bacon>, [">= 1.1.0"])
      s.add_dependency(%q<em-spec>, [">= 0.2.0"])
      s.add_dependency(%q<bones>, [">= 3.2.0"])
    end
  else
    s.add_dependency(%q<eventmachine>, [">= 0.12.10"])
    s.add_dependency(%q<bacon>, [">= 1.1.0"])
    s.add_dependency(%q<em-spec>, [">= 0.2.0"])
    s.add_dependency(%q<bones>, [">= 3.2.0"])
  end
end
