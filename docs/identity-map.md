# Service Identity Map

## Overview

This project uses certificate-based identities issued by `step-ca` to support Zero Trust communication between services. Each service must authenticate with a valid certificate instead of being trusted automatically based on network location.

## Service Identities

| Service | Identity | Description |
|---|---|---|
| Frontend | `frontend.local` | User-facing web application |
| API | `api.local` | Application/API service |
| Backend | `backend.local` | Backend data service |

## Intended Trust Policy

| Source | Destination | Allowed | Notes |
|---|---|---|---|
| Frontend | API | Yes | Frontend sends application requests to API |
| API | Backend | Yes | API accesses backend data |
| Frontend | Backend | No | Frontend should not directly access backend |
| Unknown / attacker | Any service | No | No valid certificate identity |
| Wrong certificate | Any protected service | No | Identity mismatch |

## Security Goal

The purpose of this identity design is to reduce implicit trust between internal services and support mutual TLS enforcement. Even if services exist on reachable networks, communication should only be allowed when the caller presents a valid, expected certificate.

## Issued Identities

- `frontend.local`
- `api.local`
- `backend.local`