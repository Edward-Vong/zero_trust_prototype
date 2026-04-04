# WireGuard placeholder

This directory is reserved for WireGuard configuration files.

## Purpose

The WireGuard service is intended to provide an encrypted overlay network between the application services and the frontend.

## What to add

- `config/wg0.conf` or the LinuxServer WireGuard config folder structure
- peer templates for the frontend and backend containers
- optional network rules to demonstrate a "compromised node" that cannot access the secure tunnel

## Notes

Running `linuxserver/wireguard` may require Docker Desktop with WSL2 and elevated networking privileges on Windows.
