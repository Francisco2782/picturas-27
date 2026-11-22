# PictuRAS frontend

The frontend uses Next.js, React, TypeScript and Bun. For integrated development,
start the Docker Compose stack from the repository root and open
[https://localhost:8080](https://localhost:8080). Nginx serves the frontend and
routes `/api-gateway/` and `/socket.io` on the same origin.

The Compose image runs a production build. After a frontend change, rebuild the
service and restart Nginx from the repository root.

```sh
docker compose up -d --build frontend
docker compose restart nginx
```

From this directory, `bun install` installs the frontend dependencies and
`bun run dev` starts the Next.js development server on port 3000. Integrated API
and Socket.IO traffic requires the Nginx setup above.

Run the processing status tests from the repository root.

```sh
node --test frontend/tests/processing-status.test.mjs
```

See the [project README](../README.md) for stack setup and troubleshooting.
