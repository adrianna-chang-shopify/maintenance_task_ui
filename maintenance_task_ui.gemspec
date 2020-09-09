$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "maintenance_task_ui/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "maintenance_task_ui"
  spec.version     = MaintenanceTaskUi::VERSION
  spec.authors     = ["Adrianna Chang"]
  spec.email       = ["adrianna.chang@shopify.com"]
  spec.homepage    = "https://github.com/adrianna-chang-shopify/maintenance_task_ui"
  spec.summary     = "A web application for queuing and managing maintenance tasks"
  spec.description = <<~EOM
    This gem offers a UI for managing maintenance tasks. Maintenance tasks can be run,
    paused, and resumed through the application. The progress of running tasks can be
    observed as well.
  EOM

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = 'http://mygemserver.com'
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.0.3", ">= 6.0.3.2"

  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "byebug"
end
