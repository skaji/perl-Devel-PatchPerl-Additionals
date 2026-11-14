use v5.24;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Devel::PatchPerl::SKAJI;
use version;

my $dir = tempdir(CLEANUP => 1);
mkdir "$dir/hints" or die $!;
my $file = "$dir/hints/darwin.sh";

sub write_hints {
    open my $out, '>', $file or die $!;
    print {$out} $_[0];
    close $out or die $!;
}

sub read_hints {
    open my $in, '<', $file or die $!;
    local $/;
    return <$in>;
}

for my $version (qw(5.23.5 5.23.6 5.36.3 5.37.0 5.37.1)) {
    write_hints("# hints\n");
    local $^O = 'darwin';
    Devel::PatchPerl::SKAJI->patchperl_darwin_safe_putenv(source => $dir, version => version->parse($version));
    my $expected = version->parse($version) >= v5.23.6 && version->parse($version) <= v5.37.0;
    is !!(read_hints() =~ /-DPERL_USE_SAFE_PUTENV/), !!$expected, "$version: applicable range";
}

{
    local $^O = 'darwin';
    write_hints("# hints\n");
    Devel::PatchPerl::SKAJI->patchperl_darwin_safe_putenv(source => $dir, version => version->parse('5.36.3'));
    my $once = read_hints();
    Devel::PatchPerl::SKAJI->patchperl_darwin_safe_putenv(source => $dir, version => version->parse('5.36.3'));
    is read_hints(), $once, 'does not add the fix twice';
}

{
    local $^O = 'linux';
    write_hints("# hints\n");
    Devel::PatchPerl::SKAJI->patchperl_darwin_safe_putenv(source => $dir, version => version->parse('5.36.3'));
    is read_hints(), "# hints\n", 'does not change Linux hints';
}

done_testing;
