#!/usr/bin/env ruby
# 
# Removes a node from dashboard.
# Current bugs in dashboard (v1.0.0rc2) at times make it impossible to remove a node using a GUI
#
# The script can take multiple arguments.
# Have to be executed on the dashboard server, which is true for all the dashoard scripts at the moment

# until I will package this library, or merge it into spk library, adding lib path for convenience.
$: << 'lib'

raise StandardError, "You must provide a nodename(s)." if ARGV.empty?

require 'spk_dashboard'

ARGV.each do |node|
  unless obj = SpkDashboard::LoadData.get_node_obj( node )
    puts "Didn't find #{node} in Dashboard."
    next
  end 
  
  puts SpkDashboard::LoadData.rm_node(obj.name)
end
