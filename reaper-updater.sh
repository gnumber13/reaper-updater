#!/bin/sh
# dependencies: libxml curl tar posix-shell 
# tested with bash and dash

# global variables
URL="https://www.reaper.fm"

################ functions ####################
#
get_dl_path() {
    # parent of download button wich is a link, that contains linux_x86_64 => download link
    xpath_string="//img[@class='downloadbutton']/parent::a[contains(@href,'linux_x86_64')]/@href"
    curl -s  $URL/download.php | xmllint --html --xpath $xpath_string - | cut -d'=' -f2 | tr -d "\""
}

string_contain() {
    _ret=1
    case $2 in
        *$1*)
            _ret=0
        ;;
    esac
    return $_ret
}

reaper_dl() {
    #aria2c $dl_link --dir=/tmp
    #wget --directory-prefix=/tmp $dl_link
    _pwd=$(pwd)
    cd /tmp && curl -OL "$dl_link" && cd "$_pwd" || exit
}
reaper_unpack() {
    tar  -xaf /tmp/reaper*.tar.xz --directory=/tmp
}

reaper_install() {
	[ -n "$install_path" ] && install_path="${install_path%/}"
    [ -z "$install_path" ] && install_path="$HOME/.local/opt"
    bash /tmp/reaper_linux_x86_64/install-reaper.sh --install "$install_path" --integrate-user-desktop
}

reaper_remove() {
    rm -f /tmp/reaper*.tar.xz
    rm -rf /tmp/reaper_linux_x86_64
}
reaper_archive() {
    echo "checking if contains ~"
    string_contain '~' "$1" && rel_to_home=$(echo "$1" | tr -d "~") && echo "$HOME$rel_to_home" && mkdir -p "$HOME$rel_to_home" && mv /tmp/reaper*.tar.xz "$HOME$rel_to_home"
    string_contain '~' "$1" || mv /tmp/reaper*.tar.xz "$1"
}
###################################################


################ option checking ##################
for tag in "$@";do
    case "$tag" in  
        '-a'*|'--archive'*)
            archive_path="$(echo "$tag" | cut -d' ' -f2-)"
            [ -z "$archive_path" ] && archive_path="$(xdg-user-dir DOWNLOAD)"
        ;;
        '-g'|'--get-only')
            archive_path="$(xdg-user-dir DOWNLOAD)"
            download_only=0
        ;;

        '-p'|'--path')
            install_path="$(echo "$tag" | cut -d' ' -f2- | tr -s '/')"
        ;;
        'help'|'-h'|'--help')
            #groff -Tascii -man test.1 | less
            printf '
USAGE:
./reaper-updater.sh [options] 

NOTE:
Without any arguments Reaper will be installed to the directory: ~/.local/opt (no prompt necessary)
And the downloaded tarball file will be discarded.

OPTIONS:
\t[--help | -h | help]
\t:\tshow help page

    The tarball by default will be discarded after execution 
    to save it use the -a option.
\t[-a <ARCHIVEPATH>|--archive <ARCHIVEPATH>]
\t:\tset your path of preference
\t\tfor the script to save the tarball to

     
\t[-g|--get-only] : Download reaper tarball without installing.
\t:\tWithout the ARCHIVEPATH set it will be downloaded in ~/Downloads

EXAMPLES:

Install only to ~/.local/opt:
./reaper-updater.sh

Install only to any directory:
./reaper-updater.sh --path <ANY_DIRECTORY>

Install to any directory and archive to another:
./reaper-updater.sh --path <ANY_DIRECTORY> --archive <OTHER_DIRECTORY>

Download to default Downloads directory:
./reaper-updater.sh --archive --get-only

Download to any directory:
./reaper-updater.sh --archive <ANY_DIRECTORY> --get-only
'
            exit
        ;;

        *)
            break
        ;;
    esac
done
###################################################

############## main programm ######################

dl_path=$(get_dl_path)
dl_link="$URL/$dl_path"

reaper_remove

reaper_dl

# check if variable is declared. if so execute
if [ -n "$archive_path" ]; then
    echo "Archiving to: $archive_path"
    reaper_archive "$archive_path"
fi

# check if variable is declared. if so dont execute
if [ -z "$download_only" ]; then
    reaper_unpack
    reaper_install
    echo "Reaper has now been installed"
else
    echo "not installing"
fi

reaper_remove

####################################################
