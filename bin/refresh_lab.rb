#!/usr/bin/env ruby
#

$: << 'lib'

require 'spk_dashboard'

# we don't need to remove classes

# remove groups, but first remove nodes.
Node.all.each do |node|
    if node.name.match(/eric99|^default/)
        puts "SKIPPED: #{node.name} is in eric99 pop."
    else
        # puts "Will remove #{node.name}."
        puts SpkDashboard::LoadData.rm_node(node.name)
    end
end

NodeGroup.all.each do |group|
    # puts "Will remove group #{group.name}" unless group.name.match(/eric99/)
    puts SpkDashboard::LoadData.rm_node_group( group.name ) unless group.name.match(/eric99|spk_base/)
end
