complete -c vv -s h -l help -d 'Show help'
complete -c vv -l verified-version -l version -d 'Show vv version'
complete -c vv -l quarantine -d 'List or explain quarantined tools' -f -a '(__fish_complete_command)'
complete -c vv -f -a '(__fish_complete_command)'
