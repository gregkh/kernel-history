#!/usr/bin/perl -w
#
# Stupid 'how much work is going on' type calculations for the Linux kernel
# source tree.
#
# Copyright (C) 2007-2008 Greg Kroah-Hartman <greg@kroah.com>
# Copyright (C) 2007-2008 Novell Inc.
#
# Released under the GPL version 2 only.
#
# How to use:
#  - go into the git tree for the kernel and run the script, passing the two
#    git ids that you wish to calculate between as command line arguments.
#  - be amazed at the huge rate of change that happens...
#
# Note, some file names might show up as "unknown" because of some wierd git
# thing, if so, please let me know.
#
# How rate of change is calculated:
#   - we look at every changeset between the requested tags
#   - for every changeset, we tell git to not show us renames or file moves
#   - we look at the diffstat for the individual files within the changeset and
#     calculate things as:
#        file_lines_added = diffstat lines added
#        file_lines_delete = diffstat lines added
#        if (file_lines_added = file_lines_deleted)
#           overall_lines_modified += file_lines_added
#        if (file_lines_added > file_lines_deleted)
#           overall_lines_added += file_lines_added - file_lines_deleted
#           overall_lines_modified += file_lines_deleted
#        if (file_lines_added < file_lines_deleted)
#           overall_lines_deleted += file_lines_deleted - file_lines_added
#           overall_lines_modified += file_lines_added
#     Yeah, it's not the cleanest formula, but it is the best that I can come
#     up with after trying a lot of different ones.  If anyone knows a better
#     one, please let me know.
#
#
#

my $start = "";
my $end = "";

my @core_files = ("init", "block", "ipc", "kernel", "lib", "mm", "virt");
my @fs_files = ("fs");
my @driver_files = ("crypto", "drivers", "sound", "security");
my @net_files = ("net");
my @arch_files = ("arch");
my @misc_files = ("Documentation", "scripts", "samples", "usr", "MAINTAINERS", "CREDITS", "README", ".gitignore", "Kbuild", "Makefile", "REPORTING-BUGS", ".mailmap", "COPYING", "tools", "Kconfig");
my @firmware_files = ("firmware");

my $overall_add = 0;
my $overall_del = 0;
my $overall_mod = 0;
my $core_add = 0;
my $core_del = 0;
my $core_mod = 0;
my $fs_add = 0;
my $fs_del = 0;
my $fs_mod = 0;
my $driver_add = 0;
my $driver_del = 0;
my $driver_mod = 0;
my $net_add = 0;
my $net_del = 0;
my $net_mod = 0;
my $arch_add = 0;
my $arch_del = 0;
my $arch_mod = 0;
my $misc_add = 0;
my $misc_del = 0;
my $misc_mod = 0;
my $firmware_add = 0;
my $firmware_del = 0;
my $firmware_mod = 0;

sub unknown($$$$$)
{
	my ($filename, $commit, $add, $del, $mod) = @_;
	print "unknown filename='$filename' commit=$commit add=$add del=$del mod=$mod\n";
}

sub include_category($$$$$);
sub include_category($$$$$)
{
	my ($filename, $commit, $add, $del, $mod) = @_;

	if (($filename eq "linux") ||
	    ($filename eq "keys") ||
	    ($filename eq "trace") ||
	    ($filename eq "uapi") ||
	    ($filename eq "Kbuild")) {
		$core_add += $add;
		$core_del += $del;
		$core_mod += $mod;
	} elsif (($filename eq "acpi") ||
		 ($filename eq "clocksource") ||
		 ($filename eq "crypto") ||
		 ($filename eq "drm") ||
		 ($filename eq "media") ||
		 ($filename eq "mtd") ||
		 ($filename eq "pcmcia") ||
		 ($filename eq "target") ||
		 ($filename eq "rdma") ||
		 ($filename eq "rxrpc") ||
		 ($filename eq "scsi") ||
		 ($filename eq "ras") ||
		 ($filename eq "sound") ||
		 ($filename eq "kvm") ||
		 ($filename eq "video")) {
		$driver_add += $add;
		$driver_del += $del;
		$driver_mod += $mod;
	} elsif (($filename eq "net")) {
		$net_add += $add;
		$net_del += $del;
		$net_mod += $mod;
	} elsif (($filename eq "xen") ||
		 ($filename eq "math-emu") ||
		 ($filename eq "dt-bindings")) {
		$arch_add += $add;
		$arch_del += $del;
		$arch_mod += $mod;
	} else {
		# see if this is arch
		my @a = split(/-/,$filename);
		if ($a[0] eq "asm") {
			$arch_add += $add;
			$arch_del += $del;
			$arch_mod += $mod;
		} else {
			# see if the first char is the '{'
			if (substr($filename, 0, 1) eq "\{") {
				# it is, so strip it off (hack, hack, hack...)
				my $l = length($filename);
				$filename = substr($filename, 1, $l-1);
				include_category($filename, $commit, $add, $del, $mod);
			} else {
				print "unknown include filename='$filename' commit=$commit add=$add del=$del mod=$mod\n";
			}
		}
	}
}

sub filename_category($$$$$)
{

	my ($filename, $commit, $add, $del, $mod) = @_;
	my @f = split(/\//,$filename);
	my $basename = $f[0];

	if ($basename eq "include") {
		include_category($f[1], $commit, $add, $del, $mod);
	} elsif (grep { /$basename/ } @core_files) {
		$core_add += $add;
		$core_del += $del;
		$core_mod += $mod;
	} elsif (grep { /$basename/ } @fs_files) {
		$fs_add += $add;
		$fs_del += $del;
		$fs_mod += $mod;
	} elsif (grep { /$basename/ } @driver_files) {
		$driver_add += $add;
		$driver_del += $del;
		$driver_mod += $mod;
	} elsif (grep { /$basename/ } @net_files) {
		$net_add += $add;
		$net_del += $del;
		$net_mod += $mod;
	} elsif (grep { /$basename/ } @arch_files) {
		$arch_add += $add;
		$arch_del += $del;
		$arch_mod += $mod;
	} elsif (grep { /$basename/ } @misc_files) {
		$misc_add += $add;
		$misc_del += $del;
		$misc_mod += $mod;
	} elsif (grep { /$basename/ } @firmware_files) {
		$firmware_add += $add;
		$firmware_del += $del;
		$firmware_mod += $mod;
	} else {
		unknown($filename, $commit, $add, $del, $mod);
	}

}


sub print_data($$$$)
{
	my ($basename, $add, $del, $mod) = @_;
	my $percent_add = $overall_add ? $add/$overall_add*100 : 0;
	my $percent_del = $overall_del ? $del/$overall_del*100 : 0;
	my $percent_mod = $overall_mod ? $mod/$overall_mod*100 : 0;

	print "\n$basename:\n";
	printf "\tadded    = %8d\t%6.2f", $add, $percent_add;
	print "%\n";
	printf "\tdeleted  = %8d\t%6.2f", $del, $percent_del;
	print "%\n";
	printf "\tmodified = %8d\t%6.2f", $mod, $percent_mod;
	print "%\n";
}

sub error_out
{
	print "ERROR, must provide 2 git ids to calculate between\n";
	die;
}

$start = shift;
$end = shift;

if (($start eq "") || ($end eq "")) {
	error_out;
}

print "Figuring stats for $start to $end\n";

open GIT, "git rev-list --no-merges $start..$end | " || die "cant run git";

my $commit;
my $file_add;
my $file_del;
my $filename;
my $num_commits = 0;

while (<GIT>) {
	$num_commits++;
	chomp;
	my @arr = split;
	$commit = $arr[0];
	# print "commit = $commit\n";
	# system("git show --pretty=oneline --numstat $commit > genstat.$commit");

	open DIFF, "git show --pretty=oneline --numstat $commit |";
	my $temp = <DIFF>;
	while (<DIFF>) {
		my $mod = 0;
		my $del = 0;
		my $add = 0;
		chomp;
		my @file_arr = split;
		$file_add = $file_arr[0];
		$file_del = $file_arr[1];
		$filename = $file_arr[2];

		# if this is a binary file, there will not be any add or del
		# numbers, only "-" in these fields
		if (($file_add eq "-") || ($file_del eq "-")) {
			next;
		}

		# if this is a renamed file, we will have a "{" in it
		if ($filename =~ m/\{/) {
			# if there is a clean move, we don't care about it.
			# This makes things easier for some of the bigger i386 to x86
			# merged files
			if (($file_add == 0) && ($file_del == 0)) {
				# print "$filename no add or del, moving on...\n";
				next;
			}

			# see if the first char is the '{'
			if (substr($filename, 0, 1) eq "\{") {
				# it is, so strip it off (hack, hack, hack...)
				my $l = length($filename);
				$filename = substr($filename, 1, $l-1);
			}
		}

		# compute the number of modified lines for this file

		if ($file_add == $file_del) {
			# print "equal\n";
			$mod = $file_add;
		} elsif ($file_add < $file_del) {
			# print "add less than del\n";
			$mod = $file_add;
			$del = $file_del - $file_add;
		} else {
			# print "add greater than del\n";
			$mod = $file_del;
			$add = $file_add - $file_del;
		}
		$overall_add += $add;
		$overall_del += $del;
		$overall_mod += $mod;
		# print ("mod = $mod add = $add del = $del\n");
		# print "$filename\n";
		filename_category($filename, $commit, $add, $del, $mod);
	}
	close DIFF;
}

print "number of commits = $num_commits\n";
print "added    = $overall_add\n";
print "deleted  = $overall_del\n";
print "modified = $overall_mod\n";

print_data("core", $core_add, $core_del, $core_mod);
print_data("drivers", $driver_add, $driver_del, $driver_mod);
print_data("arch", $arch_add, $arch_del, $arch_mod);
print_data("net", $net_add, $net_del, $net_mod);
print_data("filesystems", $fs_add, $fs_del, $fs_mod);
print_data("misc", $misc_add, $misc_del, $misc_mod);
print_data("firmware", $firmware_add, $firmware_del, $firmware_mod);

exit;

