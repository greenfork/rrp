use POFile;

unit module Gettext;

our $po;

sub gettext-init(Str:D $lang) is export {
    $po = POFile.load(%?RESOURCES{"translations/$lang/default.po"});
}

multi gettext(Str:D $text) is export {
    with $po{$text} {
        $_.msgstr || $text andthen .subst('\n', "\n"):g;
    } else {
        say "Missing translation: $text";
        $text;
    }
}

multi gettext(Str:D $text, |args) is export {
    with $po{$text} {
        sprintf($_.msgstr || $text, |args) andthen .subst('\n', "\n"):g;
    } else {
        say "Missing translation: $text";
        $text;
    }
}
