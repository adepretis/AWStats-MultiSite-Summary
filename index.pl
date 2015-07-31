#!/usr/bin/perl
#
#                         AWStats MultiSite Summary
#
#                                Version 1.8
#
#     Copyright (C) 2004 - 2006 25th-floor - de Pretis & Helmberger KEG.
#                            All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple·
# Place, Suite 330, Boston, MA  02111-1307  USA
#
use strict;
use warnings;

use File::Spec::Functions;
use File::Find::Rule;
use FindBin;
use Template;
use Math::Round::Var;
use File::Slurp;
use Switch;
use CGI qw/:cgi/;

use constant TRUE => 1;
use constant FALSE => 0;

#
# Configuration
#
my $awstats_config_dir = '/etc/awstats';                    # directory where AWStats config files are stored
my $awstats_uri = '/awstats.pl';                            # URI to awstats.pl
my $template_root = $FindBin::Bin . '/_system/templates';   # Template basedir (relative or absolute)
my $refresh_interval = 600;                                 # http meta refresh, set to 0 to disable

################# No need to change anything below this line ##################

# Variables
my $content = '';
my %params = ();
my %data = (
    'awstats' => $awstats_uri,
    'version' => '1.8',
    'sites'   => [],
);

# Instance Template-Toolkit object
my $tt ||= Template->new(
    ABSOLUTE     => 1,
    COMPILE_EXT  => '.ttc',
    COMPILE_DIR  => '/tmp/ttc',
    INCLUDE_PATH => $template_root,
) or die Template::ERROR();

# instance various objects
my $rounder = Math::Round::Var::Float->new(precision => 2);
my $cgi = CGI->new();

# get user information
$data{username} = $ENV{REMOTE_USER} || die "Error: no username given";

# set refresh interval for http meta refresh
$data{refresh} = $refresh_interval;

# check for params
_parse_params();

# get available config files
my @files = File::Find::Rule->file
                            ->name("awstats.*?\.conf")
                            ->relative
                            ->in($awstats_config_dir);

my $cachedir = '';
my $sitedomain = '';
my $authrequired = FALSE;
my $authenticated = FALSE;
my $configname = '';

foreach my $configfile (@files) {

    $cachedir = '';
    $sitedomain = '';
    $authenticated = 0;

    #
    # extract config name for direct linking
    #
    ($configname = $configfile) =~ s/awstats\.(.*?)\.conf/$1/;

    parse_config(catfile($awstats_config_dir, $configfile));

    # check for allowed users containing current user
    if ($authrequired && $authenticated) {

        #
        # process awstats cache dir (get the most actual history file)
        #
        if (my $history = (
                        map { $_->[0] }
                        sort { $a->[1] <=> $b->[1] }
                        map { [$_, ((stat catfile($cachedir, $_))[9])]; }
                           File::Find::Rule->file
                            ->name(qr/awstats[0-9]{6}.$configname.txt$/)
                            ->relative
                            ->in($cachedir)
                        )[-1]) {

            my $visitors = 0;
            my $visits = 0;
            my $pages = 0;
            my $hits = 0;
            my $bandwidth = 0;
            my $bandwidth_bytes = 0;
            my $bandwidth_suffix = 'B';
            my $lastupdate = 'n/a';
            my $lasttime = 'n/a';
            my $startacc = FALSE;

            #
            # get overall statistical values (from last array element = last modified
            # history file)
            #
            open (HISTORY, catfile($cachedir, $history))
                or die "Error: couldn't open " . catfile($cachedir, $history). ": $!";
            while (<HISTORY>) {
                chomp;

                ($visitors = $_) =~ s/TotalUnique\s+([0-9]+)/$1/
                    if ($_ =~ m/^TotalUnique/);
                ($visits = $_) =~ s/TotalVisits\s+([0-9]+)/$1/
                    if ($_ =~ m/^TotalVisits/);
                ($lastupdate = (split /\s+/, $_)[1]) =~ s/LastUpdate\s+([0-9]+)/$1/
                    if ($_ =~ m/^LastUpdate/);
                ($lasttime = (split /\s+/, $_)[1]) =~ s/LastTime\s+([0-9]+)/$1/
                    if ($_ =~ m/^LastTime/);

                #
                # accumulate values (pages, hits, bandwidth)
                #
                if ($_ =~ m/^BEGIN_DAY [0-9]+/) {
                    $startacc = TRUE;
                    next;
                } elsif ($_ =~ m/^END_DAY/) {
                    $startacc = FALSE;
                    next;
                }

                if ($startacc) {
                    my @values = split /\s+/, $_;

                    $pages += $values[1];
                    $hits += $values[2];
                    $bandwidth_bytes = $bandwidth += $values[3];
                }
            }
            close(HISTORY);

            #
            # modify bandwidth to display bytes, kb, mb or gb
            #
            for (1..3) {
                if ($bandwidth / 1024 >= 1) {
                    $bandwidth = $rounder->round($bandwidth / 1024);

                    switch ($_) {
                        case 1  { $bandwidth_suffix = 'Kb' }
                        case 2  { $bandwidth_suffix = 'Mb' }
                        case 3  { $bandwidth_suffix = 'Gb' }
                    }
                }
            }

            #
            # modify lastupdate date
            #
            $lastupdate =~ s/([0-9]{4})([0-9]{2})([0-9]{2}).*/$1-$2-$3/;

            #
            # modify lasttime date
            #
            $lasttime =~ s/([0-9]{4})([0-9]{2})([0-9]{2}).*/$1-$2-$3/;

            #
            # assign values for template
            #
            push @{$data{sites}}, {
                'name'             => $sitedomain,
                'configname'       => $configname,
                'visitors'         => $visitors,
                'visits'           => $visits,
                'pages'            => $pages,
                'hits'             => $hits,
                'bandwidth'        => $bandwidth,
                'bandwidth_bytes'  => $bandwidth_bytes,
                'bandwidth_suffix' => $bandwidth_suffix,
                'lastupdate'       => $lastupdate,
                'lasttime'         => $lasttime,
            };
        }
    }
}

# sort list
if ($params{s}) {
    @{$data{sites}} = ($params{t} eq 'alnum')
        ? sort { $$a{$params{s}} cmp $$b{$params{s}} } @{$data{sites}}
        : reverse sort { $$a{$params{s}} <=> $$b{$params{s}} } @{$data{sites}};
} else {
    @{$data{sites}} = sort { $$a{name} cmp $$b{name} } @{$data{sites}};
}

if (!scalar @{$data{sites}}) {
    #
    # User has no site configured - show an error page
    #
    $tt->process('nosite.tpl', \%data, \$content)
        or die $tt->error();
} elsif (@{$data{sites}} == 1) {
    #
    # User has only one site configured - redirect to awstats
    #
    print "Location: $data{awstats}?config=$data{sites}[0]{configname}\n\n";
    exit 0
} else {
    #
    # User has more than one site configured - show the overview
    #
    $tt->process('overview.tpl', \%data, \$content)
        or die $tt->error();
}

#
# and there we go ...
#
print "Content-type: text/html\n\n";
print $content;

exit 0;


# parse parameters
sub _parse_params {
    my %param;

    foreach ($cgi->param) {
        my @values = $cgi->param($_);

        foreach my $value (@values) {
            $param{$_}{$value}++;
        }
    }

    while (my ($key, $value) = each %param) {
        my @keys = keys %{$value};
        $params{$key} = (scalar @keys == 1) ? $keys[0] : \@keys;
    }
}

sub parse_config {
    my $configfile = shift(@_);

#    print "Reading $configfile\n";

    my @file = eval { read_file($configfile) };

    # don't die but warn if permission denied
    push @{$data{errors}} ,$@ if ($@);

    foreach my $line (@file) {

	if ($line =~ /^AllowAccessFromWebToAuthenticatedUsersOnly\s*=\s*0/) {
	    $authrequired = FALSE;
	}
	if ($line =~ /^AllowAccessFromWebToAuthenticatedUsersOnly\s*=\s*1/) {
	    $authrequired = TRUE;
	}
	if ($line =~ /^AllowAccessFromWebToFollowingAuthenticatedUsers\s*=\s*"$data{username}(\s+|")/) {
	    $authenticated = TRUE;
	} elsif ($line =~ /^AllowAccessFromWebToFollowingAuthenticatedUsers\s*=/) {
	    $authenticated = FALSE;
	}
	if ($line =~ /^DirData\s*=\s*"([^"]+)"/) {
	    $cachedir = $1;
	}
	if ($line =~ /^SiteDomain\s*=\s*"([^"]+)"/) {
	    $sitedomain = $1;
	}
	if ($line =~ /^Include\s*"([^"]+)"/) {
	    parse_config($1);
	}
    }
}
