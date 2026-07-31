# legacy-emoji (podman-edge)

Tiny HTTP JSON emoji catalog for the Skupper hybrid story. **Not** full emojivoto on Podman.

| Item | Value |
|------|-------|
| Port (container) | `8080` |
| Host publish | `127.0.0.1:18080` (override `LEGACY_EMOJI_HOST_PORT`) |
| Network | `podman-edge` (allowlisted) |
| Skupper | Connector on Podman; Listener on Kind (`legacy-emoji`) |

```bash
./run.sh
curl -s http://127.0.0.1:18080/
./stop.sh
```
