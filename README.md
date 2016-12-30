# AWStats MultiteSite Summary

What is and does AWStats MultiSite Summary exactly? Unlike other AWStats addons
this little tool summarizes multiple sites in a clear and compact way on a per
month and a per user basis.

It depends on the following AWStats settings for each site:

```
AllowAccessFromWebToAuthenticatedUsersOnly=1
AllowAccessFromWebToFollowingAuthenticatedUsers="user1 user2 user3"
```

and a seperate Apache VirtualHost (might work as subdirectory installation too)
to act as centralized AWStats "portal" (see "Apache Configuration" below).

To see a working online demo please go to [https://stats.25th-floor.com](https://stats.25th-floor.com) and login as ``awstats-mss-demo`` with password ``demo``.

## Requirements

AWStats MultiSite Summary has been tested with Perl 5.8.x and will most likely
work with all Perl5 versions.

Besides AWStats itself the following Perl modules are required and have to be installed. You can find them all on CPAN (http://search.cpan.org):

  * CGI
  * File::Find::Rule
  * File::Slurp
  * Math::Round::Var
  * Template Toolkit

## Quickstart

To install AWStats MultiSite Summary:

```
cd /path/to/DocumentRoot
tar xvf AWStats-MultiSite-Summary-1.8.tar.gz
mv AWStats-MultiSite-Summary-1.8/* .
```

Additionally AWStats' ``awstats.pl`` has to be copied to
/path/to/DocumentRoot so AWStats MultiSite Summary can link to it from its
summary page. Creating a symlink might works too - depending on your
Apache/VirtualHost configuration. For people experienced with Apache configuration there are of course other ways to do this.

## Configuring AWStats MultiSite Summary

Edit ``index.pl`` and change the following values to suit your needs. Default
values are:

```
my $awstats_config_dir = '/etc/awstats';
my $awstats_uri        = '/awstats.pl';
my $template_root      = '_system/templates';
```

**NOTE:** AWStats MultiSite Summary (= the user your Apache is running as) needs read access to both the directory containinig AWStats configuration files and AWStat's ``CacheDir``.

## Configuring AWStats

Besides a seperate AWStats configuration file for each site to be analyzed it
is strongly adviced to use the schema ``awstats.conf``, ``awstats.conf.local`` and ``awstats.sitename.conf``. 

This way you can override package/awstats defaults with system-specific values and site-specific values.

  1. ``awstats.sitename.conf``: Include ``awstats.conf`` at the **beginning**
  1. ``awstats.conf``: Include ``awstats.conf.local`` at the **end**
  2. ``awstats.conf.local``

As mentioned above for each site these parameters have to be set:

    AllowAccessFromWebToAuthenticatedUsersOnly=1
    AllowAccessFromWebToFollowingAuthenticatedUsers="user1 user2 user3"
    
You can set ``AllowAccessFromWebToAuthenticatedUsersOnly`` in ``awstats.conf.local`` for all sites and ``AllowAccessFromWebToFollowingAuthenticatedUsers`` for each site's ``awstats.sitename.conf``

Users defined here must be able to login on your AWStats "portal" (see
Configuring Apache below) via HTTP 401 Authentication and will then get an overview of all sites analysis they are allowed to access.

This way you can also define a user who is allowed to access all available AWStats sites.

If the authenticated user has access to only one AWStats site, he will be redirected to the correspondig stats. Only if the user is permitted to view multiple sites, a summary page with links to each one will be genareted.

## Configuring Apache

It is strongly advised that you create a seperate Apache VirtualHost as
centralized AWStats "portal" like e.g.

    http://stats.yoursite.com
    
Furthermore you need to enable HTTP Authentication (Basic or Digest) for AWStats MultiSite Summary to work. You can do this either for the whole ``VirtualHost`` or just a ``Location`` or ``Directory`` directive. The users you add to your UserFile (.htaccess, mod_auth_ldap, ...) have to be identical with the ones you define in the respective sites' AWStats configuration file (see ``AllowAccessFromWebToFollowingAuthenticatedUsers``). You can also use other types of Apache authentication mechanisms (e.g. LDAP), as long as it's an 401 authentication and the environment variable ``REMOTE_USER`` is available for AWStats MultiSite Summary. 

AWStats MultiSite Summary as well as AWStats itself are written in Perl so you
will also have to enable CGI support for the DocumentRoot (see example VirtualHost).

An example Apache VirtualHost would look like:

```
<VirtualHost 127.0.0.1:80>
  ServerName stats.yoursite.com
  ServerAdmin webmaster@yoursite.com

  DocumentRoot /path/to/DocumentRoot

  ErrorLog /var/log/httpd/stats_yoursite.error_log
  CustomLog /var/log/httpd/stats_yoursite.access_log combined

  <Directory /path/to/DocumentRoot>
    AuthName "HTTP Statistics"
    AuthType Basic
    AuthUserFile /etc/httpd/auth/.stats.yoursite.com
    require valid-user

    Options +ExecCGI
    AddHandler cgi-script .pl
  </Directory
</VirtualHost>
```

For information about how to create and maintain the AuthUserFile please see
the Apache documentation at

    http://httpd.apache.org/docs/mod/mod_auth.html#authuserfile

## How it works

AWStats MultiSite Summary matches the authenticated user (HTTP 401 Authentication) with available site configuration files in e.g. ``/etc/awstats``. If a match occures it opens the file, reads some configuration values and tries to open the latest corresponding AWStats cache file in "CacheDir" (e.g. ``/var/lib/awstats/sitedomain.com/`` for displaying the summary.

If no cache file can be found (e.g. AWStats hasn't analyzed a site yet) the
site will not be visibile in the summary.

## Docker

To ease up installation AWStats MultiSite Summary is also avaiable as a Docker image. Please see [https://hub.docker.com/r/25thfloor/awstats-multisite-summary/](https://hub.docker.com/r/25thfloor/awstats-multisite-summary/) for details.
    
## License

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place, Suite 330, Boston, MA  02111-1307  USA
