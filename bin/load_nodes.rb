#!/usr/bin/env ruby
# 
# This script will parse all nodes manifests, find nodes with parameters and 
# included classes, and load them all into dashboard.
# Optionaly, you can do specific pop passing it as an argument
#
# July 9, now with classes and groups ebing added all in one shot

$: << 'lib'

require 'spk_dashboard'

# if no argument passed (a pop name expected) all node manifests will be processed.
ARGV[0] ||= "**"
path = File.join( SpkDashboard::MANIFEST_ROOT, "manifests", ARGV[0], "nodes.pp" )

# add classes
SpkDashboard::LoadData.find_classes.each {|kls| puts SpkDashboard::LoadData.create_class(kls)}

# add groups, only defind in the SPK_POPs
SpkDashboard::SPK_LAB_POPS.each {|new_pop| puts SpkDashboard::LoadData.create_pop_group( new_pop)}

# Finding and exporting nodes.
Dir.glob( path ).each do |manifest|
  nodes = SpkDashboard::LoadData.find_nodes( manifest )
  nodes.each_value do |obj| 
    puts SpkDashboard::LoadData.add_node( obj )
  end
end
