# -*- encoding: utf-8 -*-
# stub: notification 0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "notification".freeze
  s.version = "0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jeremy Stell-Smith".freeze]
  s.date = "2007-07-28"
  s.description = "Notification is a one stop shop for notification, it knows how to send messages via GMail, SMS, growl, snarl, etc, and all these are exposed in a simple, uniform way.".freeze
  s.email = "jeremystellsmith@gmail.com".freeze
  s.extra_rdoc_files = ["Manifest.txt".freeze]
  s.files = ["Manifest.txt".freeze]
  s.homepage = "http://onemanswalk.com".freeze
  s.rdoc_options = ["--main".freeze, "README.txt".freeze]
  s.required_ruby_version = Gem::Requirement.new("> 0.0.0".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "Notification is a one stop shop for notification, it knows how to send messages via GMail, SMS, growl, snarl, etc, and all these are exposed in a simple, uniform way.".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 1
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<gmailer>.freeze, [">= 0.1.5"])
    s.add_runtime_dependency(%q<ruby-growl>.freeze, [">= 1.0.1"])
    s.add_runtime_dependency(%q<mocha>.freeze, [">= 0.3.2"])
    s.add_runtime_dependency(%q<hoe>.freeze, [">= 1.2.1"])
  else
    s.add_dependency(%q<gmailer>.freeze, [">= 0.1.5"])
    s.add_dependency(%q<ruby-growl>.freeze, [">= 1.0.1"])
    s.add_dependency(%q<mocha>.freeze, [">= 0.3.2"])
    s.add_dependency(%q<hoe>.freeze, [">= 1.2.1"])
  end
end
