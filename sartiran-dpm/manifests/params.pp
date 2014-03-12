class dpm::params {
  $configure_vos =  hiera("dpm::params::configure_vos", false)
  $configure_gridmap =  hiera("dpm::params::configure_gridmap", false)
  
  #cluster options
  $headnode_fqdn =  hiera("dpm::params::headnode_fqdn", "${::fqdn}")
  $disk_nodes =  hiera("dpm::params::disk_nodes","")
  $localdomain =  hiera("dpm::params::localdomain","")
  $webdav_enabled = hiera("dpm::params::webdav_enabled",false)
  
  #dpmmgr user options
  $dpmmgr_user = hiera("dpm::params::dpmmgr_user",'dpmmgr')
  $dpmmgr_uid =  hiera("dpm::params::dpmmgr_uid",1000)
  $dpmmgr_gid =  hiera("dpm::params::dpmmgr_gid",1000)

  #DB/Auth options
  $db_user =  hiera("dpm::params::db_user","dpmmgr")
  $db_pass =  hiera("dpm::params::db_pass","")
  $mysql_root_pass =  hiera("dpm::params::mysql_root_pass","")
  $token_password =  hiera("dpm::params::token_password","")
  $xrootd_sharedkey =  hiera("dpm::params::xrootd_sharedkey","")
  
  #VOs parameters
  $volist =  hiera("dpm::params::volist",[])
  $groupmap =  hiera("dpm::params::groupmap",{})
  
  #Debug Flag
  $debug = hiera("dpm::params::debug",false)

}