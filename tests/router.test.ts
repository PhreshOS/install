import { describe, expect, test } from "vitest"
import route from "../source/router.ts"

const scripts = { sh: "shell\n", ps1: "powershell\n" }

describe("install routes", function () {

    test("serves the shell bootstrap only at /sh", async function () {

        const response = route(new Request("https://install.phreshos.com/sh"), scripts)

        expect(response.status).toBe(200)

        expect(response.headers.get("content-type")).toBe("text/plain; charset=utf-8")

        expect(await response.text()).toBe(scripts.sh)
    })

    test("serves the PowerShell bootstrap only at /ps1", async function () {

        const response = route(new Request("https://install.phreshos.com/ps1"), scripts)

        expect(response.status).toBe(200)

        expect(await response.text()).toBe(scripts.ps1)
    })

    test("keeps HEAD silent", async function () {

        const response = route(new Request("https://install.phreshos.com/sh", { method: "HEAD" }), scripts)

        expect(response.status).toBe(200)

        expect(await response.text()).toBe("")
    })

    test("does not invent additional routes", async function () {

        const response = route(new Request("https://install.phreshos.com/"), scripts)

        expect(response.status).toBe(404)
    })

    test("rejects mutation methods", async function () {

        const response = route(new Request("https://install.phreshos.com/sh", { method: "POST" }), scripts)

        expect(response.status).toBe(405)

        expect(response.headers.get("allow")).toBe("GET, HEAD")
    })
})
