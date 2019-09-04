class dpm::head_disknode (
    $configure_vos =  $dpm::params::configure_vos,
    $configure_gridmap =  $dpm::params::configure_gridmap,
    $configure_bdii = $dpm::params::configure_bdii,
    $configure_star = $dpm::params::configure_star,
    $configure_default_pool = $dpm::params::configure_default_pool,
    $configure_default_filesystem = $dpm::params::configure_default_filesystem,
    $configure_repos = $dpm::params::configure_repos,
    $configure_dome =  $dpm::params::configure_dome,
    $configure_domeadapter = $dpm::params::configure_domeadapter,
    $configure_dpm_xrootd_delegation = $dpm::params::configure_dpm_xrootd_delegation,
    $configure_dpm_xrootd_checksum = $dpm::params::configure_dpm_xrootd_checksum,
    #install and configure legacy stask
    $configure_legacy =   $dpm::params::configure_legacy,
    
    #repo list
    $repos =  $dpm::params::repos,

    #cluster options
    $local_db = $dpm::params::local_db,
    $headnode_fqdn =  $dpm::params::headnode_fqdn,
    $disk_nodes =  $dpm::params::disk_nodes,
    $localdomain =  $dpm::params::localdomain,
    $webdav_enabled = $dpm::params::webdav_enabled,
    $memcached_enabled = $dpm::params::memcached_enabled,

    #dpmmgr user options
    $dpmmgr_uid =  $dpm::params::dpmmgr_uid,
    $dpmmgr_gid =  $dpm::params::dpmmgr_gid,
    $dpmmgr_user =  $dpm::params::dpmmgr_user,

    #mysql override
    $mysql_override_options =  $dpm::params::mysql_override_options,

    #DB/Auth options
    $db_user =  $dpm::params::db_user,
    $db_pass =  $dpm::params::db_pass,
    $db_host =  $dpm::params::db_host,
    $db_manage = $dpm::params::db_manage,
    $mysql_root_pass =  $dpm::params::mysql_root_pass,
    $token_password =  $dpm::params::token_password,
    $xrootd_sharedkey =  $dpm::params::xrootd_sharedkey,
    $xrootd_use_voms =  $dpm::params::xrootd_use_voms,
    $http_macaroon_secret = $dpm::params::http_macaroon_secret,

    #VOs parameters
    $volist =  $dpm::params::volist,
    $groupmap =  $dpm::params::groupmap,
    $localmap = $dpm::params::localmap,

    #Debug Flag
    $debug = $dpm::params::debug,

    #XRootd federations
    $dpm_xrootd_fedredirs = $dpm::params::dpm_xrootd_fedredirs,

    #xrootd monitoring
    $xrd_report = $dpm::params::xrd_report,
    $xrootd_monitor = $dpm::params::xrootd_monitor,
    $xrootd_tpc_options = $dpm::params::xrootd_tpc_options,

    $site_name = $dpm::params::site_name,
 
    #admin DN
    $admin_dn = $dpm::params::admin_dn,

    #admin DN
    $host_dn = $dpm::params::host_dn,

    #New DB installation vs upgrade
    $new_installation = $dpm::params::new_installation,
     
    #pools filesystem 
    $pools = $dpm::params::pools,
    $filesystems = $dpm::params::filesystems,
    $mountpoints = $dpm::params::mountpoints,

)inherits dpm::params {
   
    validate_array($disk_nodes)
    validate_bool($new_installation)
    validate_array($volist)
    validate_hash($mysql_override_options)
    
    if size($token_password) < 32 {
      fail("token_password should be longer than 32 chars")
    }

    if size($xrootd_sharedkey) < 32  {
      fail("xrootd_sharedkey should be longer than 32 chars and shorter than 64 chars")
    }

    if size($xrootd_sharedkey) > 64  {
      fail("xrootd_sharedkey should be longer than 32 chars and shorter than 64 chars")
    }
    
    $disk_nodes_str=join($disk_nodes,' ')

    if ($configure_repos){
        create_resources(yumrepo,$repos)
    }

    #
    # Set inter-module dependencies
    #
    if $configure_domeadapter {
      Class[dmlite::plugins::domeadapter::install] ~> Class[dmlite::gridftp]
    }else {
    if $configure_legacy {
        Class[lcgdm::dpm::service] -> Class[dmlite::plugins::adapter::install]
        Class[dmlite::head] -> Class[dmlite::plugins::adapter::install]
        Class[dmlite::plugins::adapter::install] ~> Class[dmlite::srm]
        Class[dmlite::plugins::adapter::install] ~> Class[dmlite::gridftp]
      }
    }
    if $configure_legacy {
      Class[lcgdm::ns::config] -> Class[dmlite::srm::service]
      Class[dmlite::plugins::mysql::install] ~> Class[dmlite::srm]
    }
    Class[dmlite::plugins::mysql::install] ~> Class[dmlite::gridftp]
    Class[fetchcrl::service] -> Class[xrootd::config]


    #
    # MySQL server setup 
    #
    if ($local_db and $db_manage ){
      if $configure_legacy {
       Class[mysql::server] -> Class[lcgdm::ns::service]
      }  
      class{'mysql::server':
    	service_enabled   => true,
        root_password => $mysql_root_pass,
	override_options => $mysql_override_options,
        create_root_user => $new_installation,
        }

    }
    if $configure_legacy {
      #
      # DPM and DPNS daemon configuration.
      #
      class{'lcgdm':
        dbflavor => 'mysql',
        dbuser   => $db_user,
        dbpass   => $db_pass,
        dbhost   => $db_host,
        dbmanage => $db_manage,
        mysqlrootpass => $mysql_root_pass,
        domain   => $localdomain,
        volist   => $volist,
        uid      => $dpmmgr_uid,
        gid      => $dpmmgr_gid,
      }

      #
      # RFIO configuration.
      #
      class{'lcgdm::rfio':
        dpmhost => $::fqdn,
      }
     
      class{'dmlite::srm':}

      #
      # Entries in the shift.conf file, you can add in 'host' below the list of
      # machines that the DPM should trust (if any).
      #
      lcgdm::shift::trust_value{
        'DPM TRUST':
          component => 'DPM',
          host      => "$disk_nodes_str $headnode_fqdn";
        'DPNS TRUST':
          component => 'DPNS',
          host      => "$disk_nodes_str $headnode_fqdn";
        'RFIO TRUST':
          component => 'RFIOD',
          host      => "$disk_nodes_str $headnode_fqdn",
          all       => true
      }
      lcgdm::shift::protocol{'PROTOCOLS':
        component => 'DPM',
        proto     => 'rfio gsiftp http https xroot'
      }
    }

    if($configure_vos){
      $newvolist = reject($volist,'\.')
      dpm::util::add_dpm_voms{$newvolist:}
    }

    if($configure_gridmap){
      #setup the gridmap file
      lcgdm::mkgridmap::file {'lcgdm-mkgridmap':
        configfile   => '/etc/lcgdm-mkgridmap.conf',
	mapfile      => '/etc/lcgdm-mapfile',
        localmapfile => '/etc/lcgdm-mapfile-local',
        logfile      => '/var/log/lcgdm-mkgridmap.log',
        groupmap     => $groupmap,
        localmap     => $localmap
      }
      
       exec{'/usr/sbin/edg-mkgridmap --conf=/etc/lcgdm-mkgridmap.conf --safe --output=/etc/lcgdm-mapfile':
        require => Lcgdm::Mkgridmap::File['lcgdm-mkgridmap'],
      	unless => '/usr/bin/test -s /etc/lcgdm-mapfile',
      }
    }

    #
    # dmlite configuration.
    #
    class{'dmlite::head':
      legacy         => $configure_legacy,
      mysqlrootpass  => $mysql_root_pass,
      domain         => $localdomain,
      volist         => $volist,
      uid            => $dpmmgr_uid,
      gid            => $dpmmgr_gid,
      adminuser      => $admin_dn,
      token_password => $token_password,
      mysql_username => $db_user,
      mysql_password => $db_pass,
      mysql_host     => $db_host,
      enable_dome    => $configure_dome,
      enable_domeadapter => $configure_domeadapter,
      enable_disknode => true,
      host_dn        => $host_dn
    }

    #
    # Frontends based on dmlite.
    #
    if($webdav_enabled){
       if $configure_domeadapter {
        Class[dmlite::plugins::domeadapter::install] ~> Class[dmlite::dav]
        Dmlite::Plugins::Domeadapter::Create_config <| |> -> Class[dmlite::dav::install]
      } else {
        Class[dmlite::plugins::adapter::install] ~> Class[dmlite::dav]
        Dmlite::Plugins::Adapter::Create_config <| |> -> Class[dmlite::dav::install]
      }
      Class[dmlite::plugins::mysql::install] ~> Class[dmlite::dav]
      Class[dmlite::install] ~> Class[dmlite::dav::config]

      class{'dmlite::dav':
        ns_macaroon_secret => $http_macaroon_secret,
      }
    }
    class{'dmlite::gridftp':
      dpmhost => $::fqdn,
      enable_dome_checksum => $configure_domeadapter,
      legacy               => $configure_legacy,
    }

    #
    # The simplest xrootd configuration.
    #
    class{'xrootd::config':
      xrootd_user  => $dpmmgr_user,
      xrootd_group => $dpmmgr_user,
    }
    if $xrd_report {
        $_xrd_report = $xrd_report
    } else {
        $_xrd_report = undef
    }
    if $xrootd_monitor {
        $_xrootd_monitor = $xrootd_monitor
    } else {
        $_xrootd_monitor = undef
    }
    class{'dmlite::xrootd':
      nodetype             => [ 'head','disk' ],
      domain               => $localdomain, 
      dpm_xrootd_debug     => $debug,
      dpm_xrootd_sharedkey => $xrootd_sharedkey,
      xrootd_use_voms      => $xrootd_use_voms,
      dpm_xrootd_fedredirs => $dpm_xrootd_fedredirs,
      xrd_report           => $_xrd_report,
      xrootd_monitor       => $_xrootd_monitor,
      xrootd_tpc_options   => $xrootd_tpc_options,
      site_name            => $site_name,
      legacy               => $configure_legacy,
      dpm_enable_dome      => $configure_dome,
      dpm_xrdhttp_secret_key => $token_password,
      xrootd_use_delegation => $configure_dpm_xrootd_delegation,
      xrd_checksum_enabled => $configure_dpm_xrootd_checksum
    } 

    if($memcached_enabled and !$configure_domeadapter)
    {
      Class[dmlite::plugins::memcache::install] ~> Class[dmlite::dav::service]
      Class[dmlite::plugins::memcache::install] ~> Class[dmlite::gridftp]

      class{'memcached':
        max_memory => 2000,
        listen_ip => '127.0.0.1',

      }
      ->
      class{'dmlite::plugins::memcache':
        expiration_limit => 600,
        posix            => 'on',
        func_counter     => 'on',
      }
    } else {
      class{'memcached':
        package_ensure => 'absent',
      }
      class{'dmlite::plugins::memcache':
        enable_memcache => false,
      }
    }

    if ($configure_bdii)
    {
      #bdii installation and configuration with default values
      include('bdii')

      # GIP installation and configuration
      if $configure_legacy {
        class{'lcgdm::bdii::dpm':
          sitename => $site_name,
          vos      => $volist ,
        }
      }
      else {
        class{'dmlite::bdii':
          site_name => $site_name,
        }
      }
    } 

    if ($configure_star)
    {
      class{'dmlite::accounting':
        site_name => $site_name,
        dbuser => $db_user,
        dbpwd => $db_pass,
        dbhost => $db_host,
        nsdbname => $ns_db,
        dpmdbname  => $dpm_db,
      }
    }
    #pools configuration
    #
    if ($configure_default_pool) {
      dpm::util::add_dpm_pool {$pools:
        legacy => $configure_legacy,
      }
    }
    #
    #
    # You can define your filesystems
    #
    if ($configure_default_filesystem) {
       file{
        $mountpoints:
          ensure => directory,
          owner => $dpmmgr_user,
          group => $dpmmgr_user,
          mode =>  '0775';
       }
       -> dpm::util::add_dpm_fs {$filesystems:
            legacy => $configure_legacy,
        }
    }
  
   include dmlite::shell
}
