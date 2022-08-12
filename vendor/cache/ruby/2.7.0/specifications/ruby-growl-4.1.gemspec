# -*- encoding: utf-8 -*-
# stub: ruby-growl 4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby-growl".freeze
  s.version = "4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Eric Hodel".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDeDCCAmCgAwIBAgIBATANBgkqhkiG9w0BAQUFADBBMRAwDgYDVQQDDAdkcmJy\nYWluMRgwFgYKCZImiZPyLGQBGRYIc2VnbWVudDcxEzARBgoJkiaJk/IsZAEZFgNu\nZXQwHhcNMTMwMjI4MDUyMjA4WhcNMTQwMjI4MDUyMjA4WjBBMRAwDgYDVQQDDAdk\ncmJyYWluMRgwFgYKCZImiZPyLGQBGRYIc2VnbWVudDcxEzARBgoJkiaJk/IsZAEZ\nFgNuZXQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCbbgLrGLGIDE76\nLV/cvxdEzCuYuS3oG9PrSZnuDweySUfdp/so0cDq+j8bqy6OzZSw07gdjwFMSd6J\nU5ddZCVywn5nnAQ+Ui7jMW54CYt5/H6f2US6U0hQOjJR6cpfiymgxGdfyTiVcvTm\nGj/okWrQl0NjYOYBpDi+9PPmaH2RmLJu0dB/NylsDnW5j6yN1BEI8MfJRR+HRKZY\nmUtgzBwF1V4KIZQ8EuL6I/nHVu07i6IkrpAgxpXUfdJQJi0oZAqXurAV3yTxkFwd\ng62YrrW26mDe+pZBzR6bpLE+PmXCzz7UxUq3AE0gPHbiMXie3EFE0oxnsU3lIduh\nsCANiQ8BAgMBAAGjezB5MAkGA1UdEwQCMAAwCwYDVR0PBAQDAgSwMB0GA1UdDgQW\nBBS5k4Z75VSpdM0AclG2UvzFA/VW5DAfBgNVHREEGDAWgRRkcmJyYWluQHNlZ21l\nbnQ3Lm5ldDAfBgNVHRIEGDAWgRRkcmJyYWluQHNlZ21lbnQ3Lm5ldDANBgkqhkiG\n9w0BAQUFAAOCAQEAOflo4Md5aJF//EetzXIGZ2EI5PzKWX/mMpp7cxFyDcVPtTv0\njs/6zWrWSbd60W9Kn4ch3nYiATFKhisgeYotDDz2/pb/x1ivJn4vEvs9kYKVvbF8\nV7MV/O5HDW8Q0pA1SljI6GzcOgejtUMxZCyyyDdbUpyAMdt9UpqTZkZ5z1sicgQk\n5o2XJ+OhceOIUVqVh1r6DNY5tLVaGJabtBmJAYFVznDcHiSFybGKBa5n25Egql1t\nKDyY1VIazVgoC8XvR4h/95/iScPiuglzA+DBG1hip1xScAtw05BrXyUNrc9CEMYU\nwgF94UVoHRp6ywo8I7NP3HcwFQDFNEZPNGXsng==\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2014-02-14"
  s.description = "A pure-ruby growl notifier for UDP and GNTP growl protocols.  ruby-growl\nallows you to perform Growl notifications from machines without growl\ninstalled (for example, non-OSX machines).\n\nWhat is growl?  Growl is a really cool \"global notification system originally\nfor Mac OS X\".\n\nYou can receive Growl notifications on various platforms and send them from\nany machine that runs Ruby.\n\nOS X: http://growl.info\nWindows: http://www.growlforwindows.com/gfw/\nLinux: http://github.com/mattn/growl-for-linux\n\nruby-growl also contains a command-line notification tool named 'growl'.  It\nis almost completely option-compatible with growlnotify.  (All except for -p\nis supported, use --priority instead.)".freeze
  s.email = ["drbrain@segment7.net".freeze]
  s.executables = ["growl".freeze]
  s.extra_rdoc_files = ["History.txt".freeze, "Manifest.txt".freeze, "README.txt".freeze]
  s.files = ["History.txt".freeze, "Manifest.txt".freeze, "README.txt".freeze, "bin/growl".freeze]
  s.homepage = "https://github.com/drbrain/ruby-growl".freeze
  s.licenses = ["BSD 3-clause".freeze]
  s.rdoc_options = ["--main".freeze, "README.txt".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2".freeze)
  s.rubygems_version = "3.1.6".freeze
  s.summary = "A pure-ruby growl notifier for UDP and GNTP growl protocols".freeze

  s.installed_by_version = "3.1.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<uuid>.freeze, ["~> 2.3", ">= 2.3.5"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.2"])
    s.add_development_dependency(%q<rdoc>.freeze, ["~> 4.0"])
    s.add_development_dependency(%q<hoe>.freeze, ["~> 3.7"])
  else
    s.add_dependency(%q<uuid>.freeze, ["~> 2.3", ">= 2.3.5"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.2"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 4.0"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.7"])
  end
end
