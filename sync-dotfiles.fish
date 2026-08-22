#!/usr/bin/env fish
#
# sync-dotfiles.fish
#
# Overwrites folders in ~/dotfiles with their live counterparts from
# ~/.config, so your dotfiles repo reflects your current running config
# before an OS reinstall. Skips anything already symlinked into
# ~/dotfiles (e.g. via stow or manual symlinks).
#
# Usage:
#   ./sync-dotfiles.fish            # backup + sync
#   ./sync-dotfiles.fish --dry-run  # show what WOULD happen, change nothing
#   ./sync-dotfiles.fish --no-backup
#
set config_dir $HOME/.config
set dotfiles_dir $HOME/dotfiles

set dry_run 0
set do_backup 1

# Anything you never want blindly overwritten/deleted from dotfiles,
# even if it lives under a matching ~/.config folder. Add as needed, e.g.
#   "history.txt" "blob_storage/" "IndexedDB/"
set excludes ".git/" "*.sock"

for arg in $argv
    switch $arg
        case --dry-run
            set dry_run 1
        case --no-backup
            set do_backup 0
        case -h --help
            echo "Usage: sync-dotfiles.fish [--dry-run] [--no-backup]"
            echo "Overwrites ~/dotfiles folders with their live ~/.config counterparts."
            echo "  --dry-run    show what would change, without changing anything"
            echo "  --no-backup  skip the pre-sync tar.gz backup of ~/dotfiles"
            exit 0
        case '*'
            echo "Unknown option: $arg" >&2
            exit 1
    end
end

if not test -d $dotfiles_dir
    echo "Error: $dotfiles_dir does not exist." >&2
    exit 1
end
if not test -d $config_dir
    echo "Error: $config_dir does not exist." >&2
    exit 1
end

set rsync_opts -a --delete
for pattern in $excludes
    set rsync_opts $rsync_opts --exclude=$pattern
end
if test $dry_run -eq 1
    set rsync_opts $rsync_opts --dry-run --itemize-changes
end

# --- Backup existing dotfiles before we clobber anything ---
if test $do_backup -eq 1 -a $dry_run -eq 0
    set backup_file $HOME/dotfiles-backup-(date +%Y%m%d-%H%M%S).tar.gz
    echo "Backing up current ~/dotfiles to $backup_file ..."
    tar -czf $backup_file -C (dirname $dotfiles_dir) (basename $dotfiles_dir)
    echo "Backup complete."
    echo
end

# True if $path is a symlink (at any point in its path) that already
# resolves into $dotfiles_dir - i.e. it's already the dotfiles copy
# being used live, so syncing it would just copy a dir onto itself.
function already_linked_to_dotfiles --argument path --argument dotfiles_dir
    if not test -e $path
        return 1
    end
    set resolved (readlink -f -- $path)
    if test "$resolved" = "$dotfiles_dir"
        return 0
    end
    string match -q "$dotfiles_dir/*" -- $resolved
end

set synced
set skipped
set linked

echo "Syncing ~/.config -> ~/dotfiles ..."
echo

for entry in $dotfiles_dir/*/
    set name (basename $entry)
    if test "$name" = ".git"
        continue
    end

    set src $config_dir/$name
    set dest $dotfiles_dir/$name

    if already_linked_to_dotfiles $src $dotfiles_dir
        echo "==> $name (skipped, ~/.config/$name is already symlinked into dotfiles)"
        set linked $linked $name
        echo
    else if test -d $src
        echo "==> $name"
        rsync $rsync_opts $src/ $dest/
        set synced $synced $name
        echo
    else
        set skipped $skipped $name
    end
end

# --- Special case: git config often lives at ~/.gitconfig (not XDG) ---
if already_linked_to_dotfiles $HOME/.gitconfig $dotfiles_dir
    echo "==> git (skipped, ~/.gitconfig is already symlinked into dotfiles)"
    set linked $linked git
    echo
else if test -f $HOME/.gitconfig
    echo "==> git (from ~/.gitconfig, not ~/.config/git)"
    if test $dry_run -eq 1
        if diff -q $HOME/.gitconfig $dotfiles_dir/git/config >/dev/null 2>&1
            echo "  (identical)"
        else
            echo "  would copy ~/.gitconfig -> dotfiles/git/config"
        end
    else
        mkdir -p $dotfiles_dir/git
        cp $HOME/.gitconfig $dotfiles_dir/git/config
    end
    echo
end

function list_or_none --argument-names items
    if test (count $items) -eq 0
        echo none
    else
        echo $items
    end
end

echo ----------------------------------------
echo "Synced ("(count $synced)"): "(list_or_none $synced)
echo "Already symlinked into dotfiles, skipped ("(count $linked)"): "(list_or_none $linked)
echo "No match in ~/.config, left untouched ("(count $skipped)"): "(list_or_none $skipped)
if test $dry_run -eq 1
    echo
    echo "This was a DRY RUN. Nothing was actually changed."
end
