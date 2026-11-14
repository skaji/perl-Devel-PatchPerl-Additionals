package Devel::PatchPerl::SKAJI v0.0.1;
use v5.24;
use warnings;
use experimental qw(lexical_subs signatures);

use Devel::PatchPerl;
use Devel::PatchPerl::SKAJI::FixCompoundTokenSplitByMacro;
use Devel::PatchPerl::SKAJI::DarwinRemoveIncludeGuard;

sub patchperl ($class, $version_without_rc, $source = ".") {
    {
        delete local $ENV{PERL5_PATCHPERL_PLUGIN};
        Devel::PatchPerl->patch_source($version_without_rc, $source);
    }

    $version_without_rc = version->parse($version_without_rc);
    $class->patchperl_db_file(version => $version_without_rc);
    $class->patchperl_fix_compound_token_split_by_macro(version => $version_without_rc);
    $class->patchperl_darwin_remove_include_guard(version => $version_without_rc);
    $class->patchperl_configure_malloc(source => $source);
    $class->patchperl_storable(source => $source, version => $version_without_rc);
    $class->patchperl_posix(source => $source, version => $version_without_rc);

}

sub patchperl_configure_malloc ($class, %argv) {
    my $file = "$argv{source}/Configure";
    open my $in, "<", $file or die "Cannot read $file: $!";
    my $mode = (stat $in)[2] // die "Cannot stat $file: $!";
    my $content = do { local $/; <$in> };
    close $in or die "Cannot close $file: $!";

    # https://github.com/Perl/perl5/commit/e1ca9a418fa6b7d26fbb1931c9164141035262c3
    my $changed = $content =~ s/(#ifdef TRY_MALLOC\n)void \*malloc\(\);/$1void *malloc(size_t);/;
    $changed += $content =~ s/(#ifdef TRY_FREE\n)void free\(\);/$1void free(void *);/;
    return 1 unless $changed;

    warn "patching $file\n";
    open my $out, ">", "$file.tmp" or die "Cannot write $file.tmp: $!";
    print {$out} $content or die "Cannot write $file.tmp: $!";
    close $out or die "Cannot close $file.tmp: $!";
    chmod $mode & 07777, "$file.tmp" or die "Cannot chmod $file.tmp: $!";
    rename "$file.tmp", $file or die "Cannot replace $file: $!";
    return 1;
}

sub patchperl_storable ($class, %argv) {
    return 1 unless v5.8.1 <= $argv{version} && $argv{version} <= v5.8.7;

    my $file = "$argv{source}/ext/Storable/Storable.xs";
    open my $in, "<", $file or die "Cannot read $file: $!";
    my $mode = (stat $in)[2] // die "Cannot stat $file: $!";
    my $content = do { local $/; <$in> };
    close $in or die "Cannot close $file: $!";

    my $changed = $content =~ s/static int store\(\);/static int store(stcxt_t *cxt, SV *sv);/;
    my $context = $argv{version} >= v5.8.4 ? "pTHX_ " : "";
    $changed += $content =~ s/SV \*\(\*\*retrieve_vtbl\)\(\);/SV *(**retrieve_vtbl)(${context}struct stcxt *, char *);/;
    return 1 unless $changed;

    warn "patching $file\n";
    open my $out, ">", "$file.tmp" or die "Cannot write $file.tmp: $!";
    print {$out} $content or die "Cannot write $file.tmp: $!";
    close $out or die "Cannot close $file.tmp: $!";
    chmod $mode & 07777, "$file.tmp" or die "Cannot chmod $file.tmp: $!";
    rename "$file.tmp", $file or die "Cannot replace $file: $!";
    return 1;
}

sub patchperl_posix ($class, %argv) {
    return 1 unless $argv{version} == v5.8.8;

    my $file = "$argv{source}/ext/POSIX/POSIX.xs";
    open my $in, "<", $file or die "Cannot read $file: $!";
    my $mode = (stat $in)[2] // die "Cannot stat $file: $!";
    my $content = do { local $/; <$in> };
    close $in or die "Cannot close $file: $!";

    # Perl 5.8.9 uses the correct signal handler type.
    my $changed = $content =~ s/(act\.sa_handler\s*=\s*DPTR2FPTR\(\s*void \(\*\))\(\)/$1(int)/;
    return 1 unless $changed;

    warn "patching $file\n";
    open my $out, ">", "$file.tmp" or die "Cannot write $file.tmp: $!";
    print {$out} $content or die "Cannot write $file.tmp: $!";
    close $out or die "Cannot close $file.tmp: $!";
    chmod $mode & 07777, "$file.tmp" or die "Cannot chmod $file.tmp: $!";
    rename "$file.tmp", $file or die "Cannot replace $file: $!";
    return 1;
}

sub patchperl_db_file ($class, %argv) {
    if ($^O ne "darwin") {
        return 1; # XXX
    }
    my $version = $argv{version};
    if ($version >= v5.10.1) {
        return 1; # OK
    }

    my $file = "ext/DB_File/Makefile.PL";
    warn "patching $file\n";

    open my $in, "<", $file or die;
    open my $out, ">", "$file.tmp" or die;

    while (my $l = <$in>) {
        print {$out} $l;
        if ($l =~ /NAME\s*=>\s*'DB_File',/) {
            print {$out} "CCFLAGS => '-Wno-incompatible-function-pointer-types',\n";
        }
    }
    close $in;
    close $out;
    rename "$file.tmp", $file or die $!;
    return 1;
}


sub patchperl_fix_compound_token_split_by_macro ($class, %argv) {
    my $version = $argv{version};

    my $name;
    if ($version >= v5.35.2) {
        return 1; # OK
    } elsif ($version >= v5.19.5) {
        $name = "5.patch";
    } elsif ($version >= v5.19.4) {
        $name = "4.patch";
    } elsif ($version >= v5.9.4 || $version == v5.8.9) {
        $name = "3.patch";
    } elsif ($version == v5.9.3 || $version == v5.8.8) {
        $name = "2.patch";
    } elsif ($version >= v5.8.1) {
        $name = "1.patch";
    } else {
        return 1; # not supported
    }
    my $patch = Devel::PatchPerl::SKAJI::FixCompoundTokenSplitByMacro->file($name);
    Devel::PatchPerl::_patch($patch);
}

sub patchperl_darwin_remove_include_guard ($class, %argv) {
    my $version = $argv{version};
    my $need_patch = $^O eq 'darwin' && (v5.8.1 <= $version && $version <= v5.8.2);
    return if !$need_patch;
    my $patch = Devel::PatchPerl::SKAJI::DarwinRemoveIncludeGuard->file("patch");
    Devel::PatchPerl::_patch($patch);
}

1;
