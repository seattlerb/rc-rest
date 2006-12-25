require 'hoe'
require './lib/rc_rest'

Hoe.new 'rc-rest', RCRest::VERSION do |p|
  p.summary = 'Robot Co-op REST web services base class'
  p.description = 'This library makes it easy to implement REST-like web services APIs.'
  p.author = 'Eric Hodel'
  p.email = 'drbrain@segment7.net'
  p.url = "http://seattlerb.rubyforge.org/rc-rest"
  p.rubyforge_name = 'seattlerb'

  p.changes = File.read('History.txt').scan(/\A(=.*?)^=/m).first.first

  p.extra_deps << ['ZenTest', '>= 3.4.2']
end

# vim: syntax=Ruby

