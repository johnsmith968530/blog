#!/usr/bin/env perl

# $Source: /Users/x/Dropbox/2/src/blog/2025/11/06/src/RCS/fullfilename.pl,v $
# $Date: 2025/11/07 02:11:08 $
# $Revision: 1.4 $

use Cwd;

sub clip {
  $_ = shift;
  s/^\/Users\/x\/Library\/CloudStorage\/Dropbox\//\/Users\/x\/Dropbox\//;
  print("$_\n");
  open(my $fh1, "|-", "pbcopy") or die "pbcopy error: $!";
  print $fh1 $_;
  close($fh1);
}

clip Cwd::abs_path($ARGV[0]);

# vim: set et ff=unix ft=perl nocp sts=2 sw=2 ts=2:
