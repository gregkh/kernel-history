#!/usr/bin/perl -w

#my $file1 = `mktemp genstat.XXXXXX`;
#FILE2=`mktemp genstat.XXXXXX` || exit1
#FILE3=`mktemp genstat.XXXXXX` || exit1
#
#

my $start = "v2.6.24-rc4";
my $end   = "v2.6.24-rc8";

print "Figuring stats for $start to $end\n";

open GIT, "git log --pretty=oneline --no-merges $start..$end | cut -f 1 -d ' ' |" || die "cant run git";

my $parent;
my $add = 0;
my $del = 0;
my $mod = 0;

while (<GIT>) {
	chomp;
	my $commit = $_;
#	print "commit = $commit\n";
	open PARENT, "git show --pretty=format:%P $commit | head -n 1 |";
	while (<PARENT>) {
		chomp;
		$parent = $_;
	}
	close PARENT;
#	print "parent = $parent\n\n";

	open DIFF, "git diff -M --numstat $parent..$commit |";
	while (<DIFF>) {
		chomp;
		my @arr = split;
	#	print "$_\n";
	#	print "add = $arr[0]\n";
	#	print "del = $arr[1]\n";
	#	print "file = $arr[2]\n";
	#	print "---\n";

		my $a = $arr[0];
		my $d = $arr[1];
		my $f = $arr[2];
		if ($a == $d) {
	#		print "equal\n";
			$mod = $mod + $a;
		} else {
			if ($a < $d) {
	#			print "add less than del\n";
				$mod = $mod + $a;
				$del = $del + $d - $a;
			} else {
	#			print "add greater than del\n";
				$mod = $mod + $d;
				$add = $add + $a - $d;
			}
		}
	#	print ("mod = $mod add = $add del = $del\n");
	}
	close DIFF;


}

print "added    = $add\n";
print "deleted  = $del\n";
print "modified = $mod\n";

exit;

#git log --pretty=oneline --no-merges v2.6.13..v2.6.14 > $FILE1
#cat $FILE1 | cut -f 1 -d ' ' > $FILE2
#rm $FILE1
#
#rm $FILE3
#touch $FILE3
#
#LINESIZE=`wc -l $FILE2 | awk '{print $1}'`
#echo "$LINESIZE changesets to work through..."
#LINENUM=0
#
#for COMMIT in `cat $FILE2`
#do
#	LINENUM=$(($LINENUM+1))
#	MOD100=$(($LINENUM/100))
#	MUL100=$(($MOD100*100))
#	if [[ $LINENUM = $MUL100 ]] ; then
#		echo -n "$LINENUM.."
#	fi
#
#	PARENT=`git show --pretty=format:%P $COMMIT | head -n 1`
##	echo "working on $COMMIT with parent $PARENT"
#	git diff -M --numstat $PARENT..$COMMIT >> $FILE3
#done
#echo ""
#
#rm $FILE2

