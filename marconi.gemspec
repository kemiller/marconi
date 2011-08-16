Gem::Specification.new do |s|
  s.name    = 'marconi'
  s.version = '0.1.1'
  s.summary = 'Message-based distributed state updates for Active Record'
  s.description = 'Implements asychronous, distributed state broadcasting for ActiveModel-like objects.'

  s.author   = 'Ken Miller'
  s.email    = 'ken.miller@gmail.com'
  s.homepage = 'https://github.com/kemiller/marconi'

  s.add_dependency 'bunny', '0.6.0'
  s.add_dependency 'activesupport'
  s.add_dependency 'uuidtools'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'shoulda'

  # Include everything in the lib folder
  s.files = Dir['lib/**/*']

  # Supress the warning about no rubyforge project
  s.rubyforge_project = 'nowarning'
end

