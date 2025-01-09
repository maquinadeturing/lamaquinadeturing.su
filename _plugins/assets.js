import fs from "fs";
import path from "path";

import sharp from "sharp";

export default function (eleventyConfig, pluginOptions = {}) {
    const assets = pluginOptions.assets || [];

    let already_processed = new Set();
    const generated_files = {};
    const inlined_files = {};
    const media_files = [];

    eleventyConfig.addShortcode("import_assets", () => {
        let asset_blocks = [];
        for (const [type, content] of Object.entries(inlined_files)) {
            asset_blocks.push(render_asset.inline[type](content));
        }
        for (const [type, load] of Object.entries(generated_files)) {
            for (const [load_type, files] of Object.entries(load)) {
                asset_blocks.push(render_asset[load_type][type](files.map((file) => eleventyConfig.getFilter("absolute_path")(file.output))));
            }
        }
        return asset_blocks.join("\n");
    });

    eleventyConfig.addFilter("srcset", (image_file_name, srcset_sizes) => {
        const default_image = media_files.find((image) => image.input.endsWith(image_file_name) && image.size === 0);
        if (!default_image) {
            throw new Error(`Image ${image_file_name} not found`);
        }
        const src = eleventyConfig.getFilter("absolute_path")(default_image.output);

        const sizes = typeof srcset_sizes === "number" ?
            [srcset_sizes] : srcset_sizes.split(",").map((size) => parseInt(size));
        let srcset = [];

        for (const size of sizes) {
            const image = media_files.find((image) => image.input.endsWith(image_file_name) && image.size === size);
            if (!image) {
                throw new Error(`Image ${image_file_name} not found`);
            }
            srcset.push(`${eleventyConfig.getFilter("absolute_path")(image.output)} ${size}w`);
        }

        return `src="${src}" srcset="${srcset.join(", ")}"`;
    });

    eleventyConfig.addFilter("image_path", (image_file_name, size) => {
        const image = media_files.find((image) => image.input.endsWith(image_file_name) && image.size === size);
        if (!image) {
            throw new Error(`Image ${image_file_name} not found`);
        }
        return eleventyConfig.getFilter("absolute_path")(image.output);
    });

    for (const asset of assets) {
        // Gather list of files for this asset configuration
        let files = [];
        if (asset.source.files) {
            files = asset.source.files;
        } else if (asset.source.directory) {
            files = fs.readdirSync(asset.source.directory).map((file) => `${asset.source.directory}/${file}`);
        } else {
            throw new Error("Invalid asset configuration");
        }

        files = files.filter((file) => !already_processed.has(file));
        already_processed = new Set([...already_processed, ...files]);

        // Exclude this files from 11ty processing
        for (const file of files) {
            eleventyConfig.ignores.add(file);
        }

        // Process files based on asset configuration
        if (asset.type === "css" || asset.type === "js") {
            const combined = files.map((file) => `/* ${file} */\n` + fs.readFileSync(file)).join("\n");
            if (asset.load === "inlined") {
                inlined_files[asset.type] = inlined_files[asset.type] || "";
                if (inlined_files[asset.type] !== "") {
                    inlined_files[asset.type] += "\n";
                }
                inlined_files[asset.type] += combined;
            } else if (asset.load === "linked" || asset.load === "deferred") {
                generated_files[asset.type] = generated_files[asset.type] || [];
                generated_files[asset.type][asset.load] = generated_files[asset.type][asset.load] || [];
                generated_files[asset.type][asset.load].push({ output: asset.output, content: combined });
            }
        } else if (asset.type === "media") {
            const default_quality = asset.format.quality || 85;
            const default_format = asset.format.type || "jpeg";
            const output_dir = asset.output;
            const format_exts = { jpeg: "jpg" };

            const profiles = asset.sizes.map((options) => {
                if (typeof options === "number") {
                    return { size: options, format: default_format, quality: default_quality };
                }
                return { size: options.size, format: options.type || default_format, quality: options.quality || default_quality };
            });

            for (const file of files) {
                const file_date = fs.statSync(file).mtime;
                media_files.push({
                    input: file,
                    output: path.join(output_dir, path.basename(file, path.extname(file)) + `_opt.${format_exts[default_format]}`),
                    format: default_format,
                    size: 0,
                    quality: default_quality,
                    date: file_date
                });
                for (const { size, format, quality } of profiles) {
                    const output = path.join(output_dir, path.basename(file, path.extname(file)) + `_opt${size}.${format_exts[format]}`);
                    media_files.push({ input: file, output, format, size, quality, date: file_date });
                }
            }
        }
    }

    // Passthrough the rest of assets
    let asset_files = listFilesRecursively("assets").filter((file) => !already_processed.has(file));
    for (const file of asset_files) {
        eleventyConfig.addPassthroughCopy(file);
    }

    eleventyConfig.on("eleventy.before", async ({ directories }) => {
        for (const [type, load] of Object.entries(generated_files)) {
            for (const [load_type, files] of Object.entries(load)) {
                for (const file of files) {
                    const output_path = path.join(directories.output, file.output);
                    console.log(`Writing asset ${output_path}`);
                    fs.mkdirSync(path.dirname(output_path), { recursive: true });
                    fs.writeFileSync(output_path, file.content);
                }
            }
        }

        for (const { input, output, format, size, quality, date } of media_files) {
            if (format === "jpeg") {
                const output_path = path.join(directories.output, output);
                if (fs.existsSync(output_path) && fs.statSync(output_path).mtime > date) {
                    continue;
                }

                fs.mkdirSync(path.dirname(output_path), { recursive: true });

                if (size > 0) {
                    await sharp(input)
                        .resize(size)
                        .jpeg({ quality })
                        .toFile(output_path);
                } else {
                    await sharp(input)
                        .jpeg({ quality })
                        .toFile(output_path);
                }

                const original_size = fs.statSync(input).size;
                const optimized_size = fs.statSync(output_path).size;
                const saved = Math.round(((optimized_size - original_size) / original_size) * 100);

                console.log(`Writing media ${output_path} (${saved}%)`);
            } else {
                throw new Error("Unsupported format");
            }
        }
    });
}

function listFilesRecursively(directory) {
    let results = [];
    const files = fs.readdirSync(directory);

    files.forEach((file) => {
        const fullPath = path.join(directory, file);
        if (fs.statSync(fullPath).isDirectory()) {
            results = results.concat(listFilesRecursively(fullPath));
        } else {
            results.push(fullPath);
        }
    });

    return results;
}

const render_asset = {
    inline: {
        css: (content) => `<style>${content}</style>`,
        js: (content) => `<script>${content}</script>`,
    },
    linked: {
        css: (urls) => urls.map((url) => `<link rel="stylesheet" href="${url}" type="text/css">`).join("\n"),
        js: (urls) => urls.map((url) => `<script src="${url}"></script>`).join("\n"),
    },
    deferred: {
        css: (urls) => `<script>
function loadStyleSheets(...sources) {
    for (const src of sources) {
        if (document.createStyleSheet) document.createStyleSheet(src);
        else {
            var stylesheet = document.createElement('link');
            stylesheet.href = src;
            stylesheet.rel = 'stylesheet';
            stylesheet.type = 'text/css';
            document.getElementsByTagName('head')[0].appendChild(stylesheet);
        }
    }
}
loadStyleSheets(${urls.map((url) => `'${url}'`).join(", ")});
</script>`,
        js: (urls) => urls.map((url) => `<script src="${url}" defer></script>`).join("\n"),
    },
};
