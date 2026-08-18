export interface InstallScripts {

    sh: string

    ps1: string
}

const headers = {

    "Cache-Control": "public, max-age=300, must-revalidate",

    "Content-Type": "text/plain; charset=utf-8",

    "X-Content-Type-Options": "nosniff"
}

/** Serve only the two stable bootstrap addresses. */
export default function route(request: Request, scripts: InstallScripts) {

    const method = request.method.toUpperCase()

    if (method !== "GET" && method !== "HEAD") return new Response("Method not allowed\n", {

        status: 405,

        headers: { ...headers, Allow: "GET, HEAD" }
    })

    const path = new URL(request.url).pathname

    const content = path === "/sh" ? scripts.sh : path === "/ps1" ? scripts.ps1 : undefined

    if (content === undefined) return new Response("Not found\n", { status: 404, headers })

    return new Response(method === "HEAD" ? null : content, { headers })
}
