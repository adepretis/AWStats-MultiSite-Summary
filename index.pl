#!/usr/bin/perl

###############################################################################
#
# AWStats MultiSite Summary 0.1
#
# For more information please have a look at http://www.25th-floor.com/oss
#
# Copyright 2004 25th-floor de Pretis & Helmberger KEG
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
###############################################################################

use strict;
use warnings;

use File::Spec::Functions;
use File::Find::Rule;
use Template;
use Math::Round::Var;
use Switch;

use constant TRUE => 1;
use constant FALSE => 0;

#
# Configuration
#
my @cacheroots = (                              # AWStats directories to check
	'/var/cache/awstats/WEB',
	'/var/cache/awstats/WEB_KZ',
);
my $awstats = '/awstats.pl';                    # URL to awstats.pl
my $template_root = '_system/templates';        # Template basedir


################### Don't change anything below this line #####################

#
# Variables
#
my $username;
my @sites = ();
my $content = '';
my %data = (
    'awstats' => $awstats,
    'version' => '0.1',
    'sites'   => [],
);

#
# Instance Template-Toolkit object
#
my $tt ||= Template->new(
    ABSOLUTE     => 1,
    COMPILE_EXT  => '.ttc',
    COMPILE_DIR  => '/tmp/ttc',
) or die Template::ERROR();
my $rounder = Math::Round::Var::Float->new(precision => 2);

#
# get user information
#
$data{username} = $ENV{REMOTE_USER} || die "Error: no username given";

#
# process awstats cache root(s)
#
foreach my $cacheroot (@cacheroots) {
	my @cachedirs = File::Find::Rule->directory->relative->in($cacheroot);

    #
    # build array containing awstats cachefiles containing the username
    # and therefore belong to the user (= a site)
    #
    # sort by mtime
    #
	foreach my $cachedir (@cachedirs) {
		if (my @files = map { $_->[0] }
                        sort { $a->[1] <=> $b->[1] }
                        map { [$_, ((stat catfile($cacheroot, $cachedir, $_))[9])]; }
                        File::Find::Rule->file
		                    ->name("awstats[0-9]*.$data{username}.txt",
                                   "awstats[0-9]*.$data{username}_*.txt")
                            ->relative
	                        ->in(catfile($cacheroot, $cachedir))) {
            my $configname;
            my $visitors = 0;
            my $visits = 0;
            my $pages = 0;
            my $hits = 0;
            my $bandwidth = 0;
            my $bandwidth_suffix = 'B';
            my $lastupdate = 'n/a';
            my $startacc = FALSE;

            #
            # get configuration name (used for linking to correct statistic)
            #
            ($configname = shift @files) =~ s/awstats[0-9]+\.(.*?)\.txt/$1/;
            
            #
            # get overall statistical values (from last array element = last modified
            # history file)
            #
            open (HISTORY, catfile($cacheroot, $cachedir, $files[-1]))
                or die "Error: couldn't open " . catfile($cacheroot, $cachedir, $files[-1]);
            while (<HISTORY>) {
                chomp;

                ($visitors = $_) =~ s/TotalUnique\s+([0-9]+)/$1/
                    if ($_ =~ m/^TotalUnique/);
                ($visits = $_) =~ s/TotalVisits\s+([0-9]+)/$1/
                    if ($_ =~ m/^TotalVisits/);
                ($lastupdate = (split /\s+/, $_)[1]) =~ s/LastUpdate\s+([0-9]+)/$1/
                    if ($_ =~ m/^LastUpdate/);

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
                    $bandwidth += $values[3];
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
            # assign values for template
            #
			push @{$data{sites}}, {
                'name'             => $cachedir,
                'configname'       => $configname,
                'visitors'         => $visitors,
                'visits'           => $visits,
                'pages'            => $pages,
                'hits'             => $hits,
                'bandwidth'        => $bandwidth,
                'bandwidth_suffix' => $bandwidth_suffix,
                'lastupdate'       => $lastupdate,
            }

            
		}
	}
}

if (!scalar @{$data{sites}}) {
    #
    # User has no site configured - show an error page
    #
    $tt->process($template_root . '/nosite.tpl', \%data, \$content)
        or die $tt->error();
} elsif (@{$data{sites}} == 1) {
    #
    # User has only one site configured - redirect to awstats
    #
    print "Location: $data{awstats}?config=$data{username}\n\n";
    exit 0
} else {
    #
    # User has more than one site configured - show the overview
    #
    $tt->process($template_root . '/overview.tpl', \%data, \$content)
        or die $tt->error();
}

#
# and there we go ...
#
print "Content-type: text/html\n\n";
print $content;

exit 0;

