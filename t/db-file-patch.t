use v5.24;
use warnings;
use Test::More;
use MIME::Base64 qw(encode_base64 decode_base64);
use Devel::PatchPerl::Additionals;

my $original = <<'PATCH';
--- mkppport.lst.org	2023-11-27 22:47:29.583961000 +0000
+++ mkppport.lst	2023-11-27 22:47:57.579971000 +0000
@@ -8,3 +8,4 @@
 ext/IPC/SysV
 ext/Time/HiRes
 ext/Win32API/File
+ext/DB_File
PATCH

my @received;
{
    no warnings 'redefine';
    local *Devel::PatchPerl::_patch_b64 = sub { push @received, decode_base64($_[0]) };
    local *Devel::PatchPerl::patch_source = sub {
        Devel::PatchPerl::_patch_b64(encode_base64($original));
        Devel::PatchPerl::_patch_b64(encode_base64("unrelated patch\n"));
        my $changed = $original =~ s/\+ext\/DB_File/\+ext\/Other/r;
        Devel::PatchPerl::_patch_b64(encode_base64($changed));
    };
    local *Devel::PatchPerl::Additionals::patchperl_db_file = sub {};
    local *Devel::PatchPerl::Additionals::patchperl_darwin_safe_putenv = sub {};
    local *Devel::PatchPerl::Additionals::patchperl_fix_compound_token_split_by_macro = sub {};
    local *Devel::PatchPerl::Additionals::patchperl_darwin_remove_include_guard = sub {};
    local *Devel::PatchPerl::Additionals::patchperl_configure_malloc = sub {};
    local *Devel::PatchPerl::Additionals::patchperl_storable = sub {};
    local *Devel::PatchPerl::Additionals::patchperl_posix = sub {};
    Devel::PatchPerl::Additionals->patchperl('5.10.0');
    Devel::PatchPerl::_patch_b64(encode_base64($original));
}

my $expected = $original =~ s/\@\@ -8,3 \+8,4 \@\@\n ext\/IPC\/SysV\n/\@\@ -9,2 +9,3 \@\@\n/r;
is $received[0], $expected, 'corrects the known DB_File patch';
is $received[1], "unrelated patch\n", 'leaves unrelated patches alone';
is $received[2], ($original =~ s/\+ext\/DB_File/\+ext\/Other/r), 'leaves changed patches alone';
is $received[3], $original, 'restores the original function after patching';
done_testing;
