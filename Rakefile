require 'momentum'
Momentum.configure do |conf|
  conf[:app_base_name] = 'gravity'
  conf[:app_layers] = ['rails-app', 'worker', 'sidekiq']
  conf[:rails_console_layer] = 'worker'
end

Rake.add_rakelib 'lib/tasks'

spec = Gem::Specification.find_by_name 'momentum'
Rake.add_rakelib "#{spec.gem_dir}/lib/tasks"
