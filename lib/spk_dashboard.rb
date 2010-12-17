module SpkDashboard
  VERSION = '0.1.2'
  
  DASHBOARD_ROOT  = '/usr/share/puppet-dashboard'
  MANIFEST_ROOT   = '/opt/spk/puppetmaster'
  DATA_PATH       = "/home/snagovpa/dashboard"
  
  SPK_LAB_POPS    = %w( 
    dev0 
    dev22 
    dev23 
    eric99 
    lab0
    neteng10      
    pavel82 
    pop1 
    pop33 
    qa5 
    qa6 
    qa7 
    qa8 
    rd10 
    rd18 
    rd22 
    sea0 )
  SPK_POPS    =%w(
    atl1
    chi1
    dfw1
    lax1
    nyc1
    sea1 
    sea5 
    sfo1 
    wdc1)

end # module SpkDashboard

RAILS_ENV       = 'production'

require SpkDashboard::DASHBOARD_ROOT + "/config/environment.rb"

require 'spk_dashboard_common'

require 'load_data'
require 'spk_node'

