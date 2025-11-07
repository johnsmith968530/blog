#!/usr/bin/env perl

# $Source: /Users/x/Dropbox/2/src/blog/2025/11/06/src/RCS/droprcsdescription.pl,v $
# $Date: 2025/11/07 02:10:23 $
# $Revision: 1.5 $

use Cwd;

$s1 = Cwd::abs_path($ARGV[0]);
$s1 =~ s/^\/home\/.\///;
$s1 =~ s/^\/Users\/x\/Library\/CloudStorage\///;
$s1 = "rcs \"-t-$s1\" \"" . $ARGV[0] . "\"";
print $s1 . "\n";
system($s1);

# vim: set et ff=unix ft=perl nocp sts=2 sw=2 ts=2:
