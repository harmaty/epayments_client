Gem::Specification.new do |s|
  s.name        = 'epayments_client'
  s.version     = '0.0.4'
  s.date        = '2015-04-23'
  s.summary     = "Epayments client"
  s.description = "Ruby wrapper for epayments JSON and SOAP API"
  s.authors     = ["Artem Harmaty"]
  s.email       = 'harmaty@gmail.com'
  s.files       = Dir["{lib}/**/*"]
  s.homepage    = 'https://github.com/harmaty/epayments_client'
  s.add_dependency 'activesupport', '>= 3.0.0'
  s.add_dependency 'savon', '>= 2.5.0'
  s.license = 'MIT'
end