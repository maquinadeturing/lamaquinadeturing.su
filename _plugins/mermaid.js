import fs from "fs";
import path from "path";
import tmp from "tmp";
import { execSync } from "child_process";
import crypto from "crypto";

tmp.setGracefulCleanup();

const CACHE_DIR = ".mermaid-cache";

export default (md) => {
    const defaultFence = md.renderer.rules.fence || ((tokens, idx) => tokens[idx].content);

    md.renderer.rules.fence = (tokens, idx, options, env, self) => {
        const token = tokens[idx];

        if (token.info.trim() === "mermaid") {
            try {
                const svg = getCachedSvg(token.content);
                return `<div class="mermaid">${svg}</div>`;
            } catch (err) {
                console.error("Mermaid rendering error:", err);
                return `<pre>${token.content}</pre>`;
            }
        }

        return defaultFence(tokens, idx, options, env, self);
    };
};

function getCachedSvg(code) {
    const hash = mermaidUniqueId(code);
    const svgPath = path.join(CACHE_DIR, `${hash}.svg`);

    if (!fs.existsSync(CACHE_DIR)) {
        fs.mkdirSync(CACHE_DIR);
    }

    if (fs.existsSync(svgPath)) {
        return fs.readFileSync(svgPath, { encoding: "utf-8" });
    }

    const svg = renderMermaidToSvg(code);
    fs.writeFileSync(svgPath, svg);
    return svg;
}

function renderMermaidToSvg(code) {
    console.log(`Rendering Mermaid diagram:\n${code}`);

    const tmpFile = tmp.fileSync({ postfix: ".mmd" });
    fs.writeFileSync(tmpFile.name, code);

    const svgFile = tmp.fileSync({ postfix: ".svg" });

    console.log(`Rendering Mermaid diagram from ${tmpFile.name} to ${svgFile.name}`);

    try {
        execSync(`npx mmdc -i ${tmpFile.name} -o ${svgFile.name}`, { encoding: "utf-8" });
        return fs.readFileSync(svgFile.name, { encoding: "utf-8" });
    } catch (err) {
        throw new Error(`Failed to render Mermaid diagram: ${err.message}`);
    } finally {
        tmpFile.removeCallback();
        svgFile.removeCallback();
    }
}

function mermaidUniqueId(code) {
    const canonical_code = code.split("\n").map(line => line.trim()).join("\n");
    return crypto.createHash("sha1").update(canonical_code).digest("hex");
}
