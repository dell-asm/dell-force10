Gem::Specification.new do |s|
  s.name        = 'dell-force10'
  s.version     = '0.0.1'
  s.licenses    = ['Dell 2014']
  s.summary     = 'Dell Force10'
  s.description = 'Dell Force10 Puppet Module'
  s.authors     = ['Dell']
  s.email       = 'asm@dell.com'
  s.homepage    = 'https://github.com/dell-asm/dell-force10'

  s.files        = Dir.glob("lib/**/*")
  s.require_path = 'lib'
end