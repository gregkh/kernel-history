#!/usr/bin/perl -w

use warnings;
use strict;

my @core_files = ("init", "block", "ipc", "kernel", "lib", "mm", "virt");
my @fs_files = ("fs");
my @driver_files = ("crypto", "drivers", "sound", "security");
my @net_files = ("net");
my @arch_files = ("arch");
my @misc_files = (
		"Documentation", "scripts", "samples", "usr",
		"MAINTAINERS", "CREDITS", "README", ".gitignore",
		"Kbuild", "Makefile", "COPYING", "REPORTING-BUGS",
		".mailmap", "tools", "Kconfig", "certs", ".cocciconfig",
		".gitattributes", ".get_maintainer.ignore", "LICENSES",
		".clang-format",
	);
my @firmware_files = ("firmware");

my $overall_lines = 0;
my $overall_files = 0;
my $core_lines = 0;
my $core_files = 0;
my $fs_lines = 0;
my $fs_files = 0;
my $driver_lines = 0;
my $driver_files = 0;
my $net_lines = 0;
my $net_files = 0;
my $arch_lines = 0;
my $arch_files = 0;
my $misc_lines = 0;
my $misc_files = 0;
my $firmware_lines = 0;
my $firmware_files = 0;

sub unknown($$$)
{
	my ($category, $filename, $lines) = @_;
	print "unknown category='$category' filename='$filename' lines=$lines\n";
}

sub include_category($$)
{
	my ($filename, $lines) = @_;

	if (($filename eq "linux") ||
	    ($filename eq "keys") ||
	    ($filename eq "trace") ||
	    ($filename eq "uapi") ||
	    ($filename eq "Kbuild")) {
		$core_lines += $lines;
		$core_files++;
	} elsif (($filename eq "acpi") ||
		 ($filename eq "clocksource") ||
		 ($filename eq "crypto") ||
		 ($filename eq "drm") ||
		 ($filename eq "kvm") ||
		 ($filename eq "media") ||
		 ($filename eq "memory") ||
		 ($filename eq "misc") ||
		 ($filename eq "mtd") ||
		 ($filename eq "pcmcia") ||
		 ($filename eq "ras") ||
		 ($filename eq "rdma") ||
		 ($filename eq "rxrpc") ||
		 ($filename eq "scsi") ||
		 ($filename eq "soc") ||
		 ($filename eq "sound") ||
		 ($filename eq "target") ||
		 ($filename eq "ufs") ||
		 ($filename eq "video")) {
		$driver_lines += $lines;
		$driver_files++;
	} elsif (($filename eq "net")) {
		$net_lines += $lines;
		$net_files++;
	} elsif (($filename eq "xen") ||
		 ($filename eq "math-emu") ||
		 ($filename eq "vdso") ||
		 ($filename eq "dt-bindings")) {
		$arch_lines += $lines;
		$arch_files++;
	} elsif ($filename eq "kunit") {
		$misc_lines += $lines;
		$misc_files++;
	} else {
		# see if this is arch
		my @a = split(/-/,$filename);
		if ($a[0] eq "asm") {
			$arch_lines += $lines;
			$arch_files++;
		} else {
			unknown("include", $filename, $lines);
		}
	}
}

sub filename_category($$)
{
	my ($filename, $lines) = @_;
	my @f = split(/\//,$filename);
	my $basename = $f[1];

	if ($basename eq "include") {
		include_category($f[2], $lines);
	} elsif (grep { /$basename/ } @core_files) {
		$core_lines += $lines;
		$core_files++;
	} elsif (grep { /$basename/ } @fs_files) {
		$fs_lines += $lines;
		$fs_files++;
	} elsif (grep { /$basename/ } @driver_files) {
		$driver_lines += $lines;
		$driver_files++;
	} elsif (grep { /$basename/ } @net_files) {
		$net_lines += $lines;
		$net_files++;
	} elsif (grep { /$basename/ } @arch_files) {
		$arch_lines += $lines;
		$arch_files++;
	} elsif (grep { /$basename/ } @misc_files) {
		$misc_lines += $lines;
		$misc_files++;
	} elsif (grep { /$basename/ } @firmware_files) {
		$firmware_lines += $lines;
		$firmware_files++;
	} else {
		unknown("files", $filename, $lines);
	}

}


sub print_data($$$)
{
	my ($basename, $lines, $files) = @_;
	my $percent_lines = $lines/$overall_lines*100;
	my $percent_files = $files/$overall_files*100;

	print "\n$basename:\n";
	printf "\tlines  = %8d\t%6.2f", $lines, $percent_lines;
	print "%\n";
	printf "\tfiles  = %8d\t%6.2f", $files, $percent_files;
	print "%\n";
}

sub word_count($)
{
	my ($filename) = @_;

	# dog slow...
	#my $wc = `cat $filename | wc -l`;
	#chomp $wc;

	open(F, "< $filename") or die "can't open $filename: $!";
	1 while <F>;
	my $wc = $.;
	close(F);

	return $wc;
}


#my $version = `ketchup -m`;
my $version = `kv`;
print "kernel version: $version\n";

open FILES, "find . -type f |" || die "cant run find";

my $parent;
my $commit;
my $file_add;
my $file_del;
my $filename;
my $num_commits = 0;

while (<FILES>) {
	$overall_files++;
	chomp;
	my @arr = split;
	my $filename = $_;

	my $wc = word_count($filename);
	$overall_lines += $wc;

	filename_category($filename, $wc);
}
close FILES;

print "files in whole tree\t$overall_files\n";
print "lines in whole tree\t$overall_lines\n";

print_data("core", $core_lines, $core_files);
print_data("drivers", $driver_lines, $driver_files);
print_data("arch", $arch_lines, $arch_files);
print_data("net", $net_lines, $net_files);
print_data("filesystems", $fs_lines, $fs_files);
print_data("misc", $misc_lines, $misc_files);
print_data("firmware", $firmware_lines, $firmware_files);


exit;

