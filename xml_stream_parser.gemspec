Gem::Specification.new do |s|
  s.name = %q{xml_stream_parser}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["craig mcmillan"]
  s.date = %q{2009-06-19}
  s.description = %q{xml_stream_parser is a *very* basic Ruby parser for xml streams, based on REXML\'s pull parser}
  s.email = %q{craig@trampolinesystems.com}
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "init.rb", "lib/instance_exec.rb", "lib/xml_stream_parser.rb", "spec/xml_stream_parser_spec.rb", "xml_stream_parser.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{this code was developed by trampoline systems [ http://trampolinesystems.com ]}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{xml_stream_parser}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{a basic library for pull parsing of large xml documents}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_development_dependency(%q<hoe>, [">= 1.12.2"])
    else
      s.add_dependency(%q<hoe>, [">= 1.12.2"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.12.2"])
  end
end
