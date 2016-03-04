#!/usr/bin/perl
print "Content-type: text/html\n\n";

print "<html><table>\n";
foreach( sort keys(%ENV) ) {
	print "<tr><td>$_<td>$ENV{$_}";
}
