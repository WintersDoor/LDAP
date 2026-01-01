#!/usr/bin/perl

use POSIX qw(strftime);

sub log_info {
    my $msg = shift;
    print STDERR "[" . strftime("%m-%d-%Y %H:%M:%S", localtime) . "] [info]  $msg\n";
}

sub log_error {
    my $msg = shift;
    print STDERR "[" . strftime("%m-%d-%Y %H:%M:%S", localtime) . "] [error]  $msg\n";
}

my ($arg1, $arg2, $inputFileName) = @ARGV;

sub replaceStringFromFile {
    my ($arg1, $arg2, $inputFileName) = @_;

    my $pattern = quotemeta($arg1);
    my $replacement = $arg2;
    $pattern =~ s/"/\\"/g;
    $replacement =~ s/"/\\"/g;

    system("perl", "-pi.bak", "-e", "s!$pattern!$replacement!g;", $inputFileName);

    if ($? == 0) {
        log_info("Successfully updated $inputFileName");
    } else {
        log_error("Failed to update $inputFileName");
    }
}

replaceStringFromFile($arg1, $arg2, $inputFileName);