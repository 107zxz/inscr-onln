use strict;
use warnings;

# Don't discriminate
local $/;

my $content;
{
    open my $fh, '<', $ARGV[0] or die $!;
    $content = <$fh>;
    close $fh;
}

$content =~ s/={7}.*?>{7}.*?(\n|$)|<{7}.*?\n//gs;

print $content;

{
    open my $fh, '>', $ARGV[0] or die $!;
    print $fh $content;
    close $fh;
}
