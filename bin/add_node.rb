#!/usr/bin/env ruby
# 
# just for Eric.
# 
# until I will package this library, or merge it into spk library, adding lib path for convenience.
$: << 'lib'

raise StandardError, "You must provide a nodename(s)." if ARGV.empty?

require 'spk_dashboard'

ARGV.each do |name|
  node = SpkDashboard::SpkNode.new(name)
  puts SpkDashboard::LoadData.add_node(node)
end
