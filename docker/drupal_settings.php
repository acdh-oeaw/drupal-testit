/**
 * adding the hash_salt
 */
$settings['hash_salt'] = 'DRUPALHASH';

/**
 * define sync directory
 */
$settings['config_sync_directory'] = '/opt/drupal-repo/config';

/**
 * set the trusted hosts
 */
/*$settings['trusted_host_patterns'] = [
  DRUPALTRUSTEDHOST
];*/

/**
 * database settings
 */
$databases['default']['default'] = array (
  'database' => 'DBNAME',
  'username' => 'DBUSER',
  'password' => 'DBPSWD',
  'prefix' => 'DBPREFIX',
  'host' => 'DBHOST',
  'port' => 'DBPORT',
  'namespace' => 'Drupal\\Core\\Database\\Driver\\mysql',
  'driver' => 'mysql',
  'init_commands' => [
    'isolation_level' => 'SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED',
  ],
);
