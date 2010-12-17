# a simple class defining node objects
class SpkDashboard::SpkNode
  attr_accessor :name, :params, :includes
  
  def initialize( name )
    @name = name
    @params = {}
    @includes = []
  end
  
  def add_includes( puppet_class )
    @includes << puppet_class
  end
  
  def add_param( key, value )
    @params[key] = value
  end

end
