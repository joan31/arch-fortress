#!/bin/bash
## SCRIPT EFI BACKUP
## /usr/local/sbin/efi_backup.sh
## By Joan https://github.com/joan31/

tar -czf "/.efibackup/efi-$(date +%Y%m%d-%H%M%S).tar.gz" -C / efi;
ls -1t /.efibackup/efi-*.tar.gz | tail -n +4 | xargs -r rm --