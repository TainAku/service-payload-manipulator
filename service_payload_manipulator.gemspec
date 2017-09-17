Gem::Specification.new do |s|
  s.name        = 'service_payload_manipulator'
  s.version     = '0.0.7'
  s.date        = '2017-08-17'
  s.summary     = "Manipulate XML payload"
  s.description = "Manipulate XML payload"
  s.authors     = ["Ekaterina Kharitonova"]
  s.email       = 'kharitonova.ev05@gmail.com'
  s.files       = ["lib/service_payload_manipulator.rb"]
  
  s.add_runtime_dependency 'nokogiri', '~> 1.8'
  
  s.add_development_dependency 'rspec', '~> 3.6'
end
