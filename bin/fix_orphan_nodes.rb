#!/usr/bin/env ruby
# 
# Find nodes that are not associated with any group and add them to it's pop group

$: << 'lib'

require 'spk_dashboard'

exceptions = %( default )
orphan_nodes = SpkDashboard::LoadData.find_orphan_nodes(exceptions)

orphan_nodes.each do |node|
  pop = SpkDashboard::LoadData.node_pop( node )
  puts SpkDashboard::LoadData.add_node_group( node, pop )
end
