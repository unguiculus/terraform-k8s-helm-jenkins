#!/usr/bin/env bash

log_start() {
    printf '\033[38;5;11m❤ %s\033[0m\n' "$1"
}

log_end() {
    printf '\033[38;5;10m✓ %s\033[0m\n' "$1"
}

log_error() {
    printf '\033[31m[ERROR] %s\033[0m\n' "$1" >&2
}
