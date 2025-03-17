# frozen_string_literal: true

vuerb = <<~RB
  #{File.read('lib/bus.rb')}
  #{File.read('lib/morph.rb')}
  #{File.read('lib/component.rb')}
  #{File.read('lib/vuerb.rb')}
RB

# require_relative only useful for development
vuerb.gsub!(/require_relative 'lib\/.+\n/, '')

Dir.mkdir('dist') unless Dir.exist?('dist')
File.write('dist/vuerb.rb', vuerb)
