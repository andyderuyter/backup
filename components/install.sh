#!/bin/bash

version="1.4.0"
SECONDS=0

set -e

echo "                                                ";
echo "           _     _ _     _                      ";
echo "  ______ _| |__ (_) |_  | |__   ___             ";
echo " |_  / _  | '_ \| | __| | '_ \ / _ \            ";
echo "  / / (_| | |_) | | |_ _| |_) |  __/            ";
echo " /___\__,_|_.__/|_|\__(_)_.__/ \___|            ";
echo "                                                ";
echo " WP Install Script $version                     ";
echo "                                                ";

# Define path
INSTALL_DIR="$HOME/public_html"

# Change to the installation directory
cd "$INSTALL_DIR"

generate_prefix () {
	pwgen -Bns 8 -1
}

generate_password () {
	pwgen -Bcns 18 -1
}

wp_db_prefix=$(generate_prefix)
wp_password=$(generate_password)

# Functions for WordPress operations
wp_download() {
	echo "STATUS: Start WordPress download"
	wp core download --locale=$wp_lang --quiet
	echo "STATUS: WordPress is downloaded"
}

wp_config() {
	echo "STATUS: Start database configuration"
	wp core config --dbname=$db_name --dbuser=$db_user --dbpass=$db_pass --dbprefix="${wp_db_prefix}_" --locale=$wp_lang --quiet
	echo "STATUS: Database is configured"
}

wp_install() {
	echo "STATUS: Start WordPress installation"
	wp core install --url=$wp_domain --title="$wp_title" --admin_user=$wp_username --admin_password=$wp_password --admin_email=$wp_email --quiet
	echo "STATUS: WordPress is installed"
}

wp_cleanup_uninstall_plugins() {
	echo "STATUS: Uninstall default WordPress plugins"
	wp plugin deactivate hello --quiet && wp plugin uninstall hello --quiet
	wp plugin deactivate akismet --quiet && wp plugin uninstall akismet --quiet
	echo "STATUS: Default WordPress plugins are uninstalled"
}

wp_cleanup_uninstall_themes() {
	echo "STATUS: Uninstall default WordPress themes (except for twentytwentyfour)"
	wp theme delete twentytwentytwo --quiet && wp theme delete twentytwentythree --quiet
	echo "STATUS: Default WordPress themes are uninstalled"
}

wp_install_plugins() {
	local plugins=(
		"limit-login-attempts-reloaded"
		"http://3.120.110.212/wordpress-default-settings/wordpress-default-settings-latest.zip"
		"disable-feeds"
		"aryo-activity-log"
		"error-log-monitor"
		"sucuri-scanner"
		"post-smtp"
		"user-switching"
        "autodescription"
	)

	echo "STATUS: Install new plugins"
	for plugin in "${plugins[@]}"; do
		wp plugin install "$plugin" --activate --quiet
	done
	echo "STATUS: New plugins are installed"

	if [[ "$wp_elementor" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		echo "STATUS: Installing Elementor (Pro) and Powerpack Elements plugins"
		wp plugin install elementor --activate --quiet
		echo "STATUS: Elementor Free plugin is installed"
        install_theme
        install_git_plugin "elementor-pro" "$wp_elementor"
        install_git_plugin "powerpack-elements" "$wp_elementor"
        echo "STATUS: Elementor (Pro) and Powerpack elements are installed"
	fi

	
	install_git_plugin "advanced-custom-fields-pro" "$wp_acf_pro"
	# install_git_plugin "content-shapers-logo" "$wp_content_shapers_logo"

	# if [[ "$wp_yoast" =~ ^([yY][eE][sS]|[yY])$ ]]; then
	# 	echo "STATUS: Installing Yoast SEO & Hide SEO Bloat plugins"
	# 	wp plugin install wordpress-seo --activate --quiet
	# 	wp plugin install so-clean-up-wp-seo --activate --quiet
	# 	echo "STATUS: Yoast SEO & Hide SEO Bloat plugins are installed"
	# fi

	if [[ "$wp_woo" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		echo "STATUS: Start WooCommerce install"
		wp plugin install woocommerce --activate --quiet
		echo "STATUS: Finished installing WooCommerce"
		configure_woocommerce
	fi
}

install_git_plugin() {
	local plugin_name=$1
	local install_flag=$2

	if [[ "$install_flag" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		echo "STATUS: Installing $plugin_name plugin"
		mkdir -p wp-content/plugins/$plugin_name/
		git init --quiet wp-content/plugins/$plugin_name/
		cd wp-content/plugins/$plugin_name/
		git remote add origin "https://bitbucket.org/zabulus-be/wp-$plugin_name/"
		git pull --quiet origin master
		cd "$INSTALL_DIR"
		wp plugin activate $plugin_name --quiet
		echo "STATUS: $plugin_name plugin is installed"
	fi
}

configure_woocommerce() {
	echo "STATUS: Setting WooCommerce options"
	wp option set woocommerce_store_address "$wc_store_address" --quiet
	wp option set woocommerce_store_address_2 "" --quiet
	wp option set woocommerce_store_city "$wc_store_city" --quiet
	wp option set woocommerce_store_postcode "$wc_store_postcode" --quiet
	wp option set woocommerce_default_country "$wc_store_default_country" --quiet
	wp option set woocommerce_show_marketplace_suggestions "no" --quiet
	wp option set woocommerce_currency "$wc_store_currency" --quiet
	echo "STATUS: Finished setting WooCommerce options"
}

wp_cleanup_general() {
	echo "STATUS: Perform a clean-up, update languages (core, plugins, and themes), and set permissions on files and folders"
	wp site empty --yes --quiet
	wp rewrite flush --quiet
	wp option set blog_public 0 --quiet
	wp option set default_pingback_flag '' --quiet
	wp option set default_ping_status closed --quiet
	wp option set default_comment_status closed --quiet
	wp option set comment_registration 1 --quiet
	wp option set comments_notify 1 --quiet
	wp option set moderation_notify 1 --quiet
	wp option set comment_moderation 1 --quiet
	wp option set comment_whitelist 1 --quiet
	wp option set timezone_string Europe/Brussels --quiet
	wp option set limit_login_lockout_notify log --quiet
	wp option set show_avatars '' --quiet
	wp option set limit_login_allowed_retries 3 --quiet
	wp option set limit_login_lockout_duration 7200 --quiet
	wp option set limit_login_valid_duration 86400 --quiet
	wp option set limit_login_allowed_lockouts 2 --quiet
	wp option set limit_login_long_duration 604800 --quiet
	wp option set limit_login_notify_email_after 2 --quiet

	if [[ "$wp_load_default_settings" =~ ^([yY][eE][sS]|[yY])$ ]]; then
		load_default_settings
	fi

	wp core language update --quiet
	wp language plugin update --all --quiet
	wp language theme update --all --quiet
	find . -type f -print0 | xargs -0 chmod 660
	find . -type d -print0 | xargs -0 chmod 750
	rm -f index.html
	echo "STATUS: Clean-up finished"
}

load_default_settings() {
	echo "STATUS: Loading WordPress Default Settings"
	wp option set wordpress_default_settings_hidemenus "a:15:{i:0;s:17:\"activity_log_page\";i:1;s:8:\"edit.php\";i:2;s:17:\"edit-comments.php\";i:3;s:19:\"separator-elementor\";i:4;s:9:\"elementor\";i:5;s:36:\"edit.php?post_type=elementor_library\";i:6;s:10:\"themes.php\";i:7;s:11:\"plugins.php\";i:8;s:9:\"users.php\";i:9;s:9:\"tools.php\";i:10;s:19:\"options-general.php\";i:11;s:15:\"wpseo_dashboard\";i:12;s:10:\"sucuriscan\";i:13;s:26:\"wordpress-default-settings\";i:14;s:7:\"postman\";}" --quiet
	wp option set wordpress_default_settings_hidewidgets "a:4:{i:0;s:19:\"dashboard_right_now\";i:1;s:18:\"dashboard_activity\";i:2;s:21:\"dashboard_quick_press\";i:3;s:17:\"dashboard_primary\";}" --quiet
	wp option set wordpress_default_settings_customids "a:2:{i:0;s:20:\"e-dashboard-overview\";i:1;s:24:\"wpseo-dashboard-overview\";}" --quiet
	wp option set wordpress_default_settings_hideadminbar "a:4:{i:0;s:7:\"updates\";i:1;s:8:\"comments\";i:2;s:11:\"new-content\";i:3;s:6:\"search\";}" --quiet
	wp option set wordpress_default_settings_generalsettings "a:4:{i:0;b:1;i:1;b:1;i:2;b:1;i:3;b:1;}" --quiet
	echo "STATUS: Finished loading WordPress Default Settings"
}

install_theme() {
    echo "STATUS: Installing Hello Elementor theme"
    wp theme install hello-elementor
    echo "STATUS: Hello Elementor theme installed"
	echo "STATUS: Cloning and activating Hello Elementor child theme"
	git clone https://github.com/elementor/hello-theme-child.git wp-content/themes/hello-theme-child
	wp theme activate hello-theme-child --quiet
	echo "STATUS: Hello Elementor child theme cloned and activated"
}

# Gather input from the user
read -p "Enter Database Name: " db_name
read -p "Enter Database User: " db_user
read -sp "Enter Database Password: " db_pass
echo
read -p "Enter WordPress Domain: " wp_domain
read -p "Enter WordPress Title: " wp_title
read -p "Enter WordPress Username: " wp_username
read -p "Enter WordPress Email: " wp_email
read -p "Enter WordPress Language (default: nl_NL): " wp_lang
wp_lang=${wp_lang:-nl_NL}

read -p "Do you want to install Elementor? (y/n) " wp_elementor
read -p "Do you want to install Advanced Custom Fields Pro? (y/n) " wp_acf_pro
# read -p "Do you want to install Content Shapers Logo plugin? (y/n) " wp_content_shapers_logo
# read -p "Do you want to install Yoast SEO? (y/n) " wp_yoast
read -p "Do you want to install WooCommerce? (y/n) " wp_woo

if [[ "$wp_woo" =~ ^([yY][eE][sS]|[yY])$ ]]; then
	read -p "Enter WooCommerce Store Address: " wc_store_address
	read -p "Enter WooCommerce Store City: " wc_store_city
	read -p "Enter WooCommerce Store Postcode: " wc_store_postcode
	read -p "Enter WooCommerce Store Default Country (e.g., BE): " wc_store_default_country
	read -p "Enter WooCommerce Store Currency (e.g., EUR): " wc_store_currency
fi

read -p "Do you want to load default settings? (y/n) " wp_load_default_settings

# Main execution
wp_download
wp_config
wp_install
wp_cleanup_uninstall_plugins
wp_cleanup_uninstall_themes
wp_install_plugins
wp_cleanup_general

# Display final message
echo "=================================================="
echo " Database and WordPress Installation Information"
echo "=================================================="
echo " Database Name: $db_name"
echo " Database User: $db_user"
echo " Database Password: $db_pass"
echo " WordPress Table Prefix: ${wp_db_prefix}_"
echo "=================================================="
echo " Website Domain: $wp_domain"
echo " Admin Username: $wp_username"
echo " Admin Password: $wp_password"
echo " Admin Email: $wp_email"
echo "=================================================="
echo " WP Install Script $version finished in $SECONDS seconds."
echo "=================================================="
