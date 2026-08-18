import powershell from "./scripts/install.ps1"
import route from "./router.ts"
import shell from "./scripts/install.sh"

const scripts = { sh: shell, ps1: powershell }

export default {

    fetch(request: Request) {

        return route(request, scripts)
    }
} satisfies ExportedHandler
