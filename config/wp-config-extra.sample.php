<?php
// Copy this file to config/wp-config-extra.php (which is gitignored) and adjust values as needed.

if ( ! defined( 'WP_HOME' ) ) {
    define( 'WP_HOME', 'http://localhost:8067' );
}

if ( ! defined( 'WP_SITEURL' ) ) {
    define( 'WP_SITEURL', 'http://localhost:8067' );
}

// Enable debugging but keep notices out of the browser output by default.
define( 'WP_DEBUG_DISPLAY', false );
define( 'WP_DEBUG_LOG', true );

/* Multisite // Currently disabled
if ( ! defined( 'WP_ALLOW_MULTISITE' ) ) {
    define( 'WP_ALLOW_MULTISITE', true );
}
// Set up via Tools -> Network Setup, then uncomment the following constants.
if ( ! defined( 'MULTISITE' ) ) {
    define( 'MULTISITE', true );
}
define( 'SUBDOMAIN_INSTALL', false );
define( 'DOMAIN_CURRENT_SITE', 'example.test' );
define( 'PATH_CURRENT_SITE', '/' );
define( 'SITE_ID_CURRENT_SITE', 1 );
define( 'BLOG_ID_CURRENT_SITE', 1 );

// */
