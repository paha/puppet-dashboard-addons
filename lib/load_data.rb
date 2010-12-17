# == A collection of methods used to load and manipulate data in migrating manifest
# == data to external store.
#  
# When dashboard REST API will become usable at any extend than current state,
# some of methods would need to be adjusted.
# 
# Some of these methods will migrate to another modules and classes, 
# dropping it all together from my scripts for now.

# --- 
# === Available methods in the order they appear in the module:
# - #add_node - adds node to dashboard
# - #make_params - converts parameters in the format dashboard expects them
# - #find_nodes - finds nodes with parameters and includes classes from manifests
# - #find_classes - finds classes from manifests files
# - #find_orphan_nodes - finds nodes in dasboard that don't have any groups assigned
# - #node_pop - returns a pop when fqdn is given
# - #add_node_group - add a group(s) to a dasboard node
# - #get_node_obj - returns dashboard node object if found provided fqdn
# - #get_group_obj - returns dashboard node object if found, expects name
# - #create_pop_group - makes a dashboard group, needs a parameters file
# - #read_group_params - reads params file for a group
# - #create_class - creates a class in dashboard

module SpkDashboard::LoadData

  include SpkDashboard::Common
  
  class << self
    
    # Adding node to the dashboard
    def add_node( node )
      # Skipping nodes that have been defined already
      return "SKIPPED. Node #{node.name} exists." if Node.find_by_name( node.name )
      
      pop = node.name.split(".")[1]
      params = self.make_params( node )
      
      # test if we have classes for this node to include
      node.includes.each do |klass|
        unless NodeClass.find_by_name( klass )
          return "SKIPPED. No #{klass} defined in dashboard, included for #{node.name}."
        end
      end
      
      return "SKIPPED #{node.name}. NodeGroup for #{pop} doen't exist." unless NodeGroup.find_by_name( pop )
      
      # if node.includes.size < 1 and node.params.size < 1
        # return "SKIPPED #{node.name}. It has neither classes or parameters assigned."
      # end

      node_new = Node.new(
        :name                   => node.name,
        :node_group_names       => [ pop ],
        :node_class_names       => node.includes,
        :parameter_attributes   => params )
        
      if node_new.save
        return "Successfully created node #{node.name}"
      else
        return "FAILED to create #{node.name}"
      end

    end # end of add_node
    
    # convert parameters hash into an array of hashes for dashboard
    def make_params( node )
      my_params = []
      node.params.each do |key, value|
        my_params << { :key => key, :value => value }
      end    
      return my_params
    end # end of self.make_params
    
    # parsing manifest files, creating instances of Snode class 
    def find_nodes( manifest )
      # storing found node names with the node object into a hash
      found_nodes = {}
      
      lines = File.open( manifest ).readlines
      lines.each do |line|
        case line
        # skipping lines that match the following:
        when /^#|\}/
          next
        
        # found node definition of puppet DSL. A @node instance variable, 
        # containing Snode object is created, and used for all the lines coming after
        # until the next node definition.
        when /^node (\S+).*\{/
          node_name = line.split[1].gsub(/\'|"/,"")
          @node = SpkDashboard::SpkNode.new( node_name )
          found_nodes[node_name] = @node
          
          # dealing with node inheritance
          if line.match(/\s+inherits\s+/)
            super_node = line.split[3].gsub(/\'|"/,"")
            next if super_node == "default"
            super_obj = found_nodes[super_node]
            super_obj.params.each { |key, value| @node.add_param( key, value ) }
            super_obj.includes.each { |klass| @node.add_includes( klass ) }
          end
        
        # Find parameters and add them to the node object
        when /^\s+\$/
          pair = line.split(" = ")
          key = pair.shift.gsub(/ /,'').delete("$")
          value = pair.join.gsub(/^\'|^\"|\'$|\"$/,"").chomp
          # by the time we got our parameter we should have the node object created
          @node.add_param( key, value )

        # Find classes included and add them to the node object
        when /^\s+include/
          klass = line.split.last.chomp
          @node.add_includes( klass ) unless klass == 'spk'
        end
      end
      
      return found_nodes
    end
    
    # Finds all the classes defined in manifests
    def find_classes
      puppetClasses = []
      Dir.glob( SpkDashboard::MANIFEST_ROOT + "/modules/**/*.pp" ).each do |manifest|
        File.read( manifest ).each do |line|
          foundClass = line.match(/^class (\S+).*\{/)
          if foundClass and puppetClasses.include?( foundClass[1] ) == false
            puppetClasses << foundClass[1]
          end
        end
      end
      
      return puppetClasses
    end
    
    # nodes that have no groups assigned, optionally exceptions could be passed
    def find_orphan_nodes( exceptions = [] )
      orphan_nodes = []
      
      Node.all.each do |node|
        next if exceptions.include?(node.name) or node.node_groups.size != 0
        orphan_nodes << node.name
      end
      
      return orphan_nodes
    end
    
    # returns a pop if fqdn is given
    def node_pop( name )
      return name.split(".")[1]
    end
    
    # add a group(s) to a dasboard node, and node object expected, and group either as a string or an array
    def add_node_group( node, group )
      node_obj = self.get_node_obj( node )
      group = group.to_a
      
      # verify that group(s) exists in dashboard
      group.each do |g|
        unless NodeGroup.find_by_name(g)
          return "SKIPPED: #{node_obj.name}. No group found for #{g}"
        end
      end
      
      # obtaining dasboard group objects 
      my_groups = []
      group.each { |n| my_groups << self.get_group_obj(n) }
      
      node_obj.node_groups = my_groups
      begin
        node_obj.save!
        return "#{node_obj.name} added to group(s) #{group.inspect}"
      rescue Exception => e
        return "FAILED to add #{node_obj.name} to #{group.inspect} group: #{e.message}"
      end
      
    end # add_group method
    
    def get_node_obj( name )  
      return Node.find_by_name( name )
    end
    
    def get_group_obj( name )
      return NodeGroup.find_by_name( name )
    end
    
    def rm_node( name )
      node_obj = self.get_node_obj( name )
      
      if node_obj.destroy
        return "Removed #{node_obj.name}"
      else
        return "FAILED to remove #{node_obj.name}"
      end
    end

    def rm_node_group( name )
        ngroup_obj = self.get_group_obj( name )

        if ngroup_obj.destroy
            return "Removed #{ngroup_obj.name}"
        else
            return "FAILED to remove #{ngroup_obj.name}"
        end
    end
    
    def rm_all_nodes ( exceptions = [] )
      Node.all.each do |node|
        unless exceptions.include?(node.name)
          puts self.rm_node( node )
        end
      end
    end
    
    # create a dashboard group, expects parameters in a file.
    def create_pop_group( name )      
      return "Group #{name} already exists." if NodeGroup.find_by_name( name )
      
      unless File.exists?( SpkDashboard::DATA_PATH + "/data_#{name}" )
        return "No params file found to create group #{name}. FILE: #{SpkDashboard::DATA_PATH + "/data_#{name}"}"
      end
      
      params = self.read_group_params( name )
        
      nodegroup = NodeGroup.new(
        :name                 => name,
        :node_group_names     => [ "spk_base" ],
        :parameter_attributes => params )
      
      if nodegroup.save 
        return "Successfully created group #{name}"
      else
        return "Failed to create group #{pop}"
      end
       
    end # #create_pop_group
    
    def read_group_params( name )
      # dashboard expects array of hashes with parameters, a hash for each pair.
      my_params = []
      
      File.read( SpkDashboard::DATA_PATH + "/data_#{name}" ).each do |line|
        pair = line.split(" = ")
        key = pair.shift.gsub(/ /,'').delete("$")
        value = pair.join.gsub(/\$\{spkpop\}/, name)
        my_params << { :key => key, :value => value }
      end
      
      return my_params
    end # #read_group_params
    
    def create_class( name )
      return "Class #{name} already exists." if NodeClass.find_by_name( name )
      addedClass = NodeClass.new( :name => name )
      
      if addedClass.save
        return "Successfully created class #{name}"
      else
        return "Failed to add #{name}"
      end
    end #create_class
        
  end # singleton class
end # module SpkDashboard::LoadData
