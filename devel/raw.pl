#!/usr/bin/perl
#
#

use v5.10;
use strict;

my $router_site='http://some.org:3333';
my $html_file='/tmp/some.html';
`curl -s -L --user adm:adm ${router_site}/userRpm/AssignedIpAddrListRpm.htm > $html_file`;

my $page;
open FD, "<  $html_file";
$page .= $_ for <FD>;
close FD;

parse_var( $page, 'DHCPDynList' );
say;

parse_var( $page, 'DHCPDynPara' );

sub parse_var {
    my $data = shift;
    my $var  = shift;

    if( $data =~ m/var $var = new Array\((.*?)\);.<\/SCRIPT>/s ) {
        say "Found [$var]: $1";
    }
}


#say $page;



