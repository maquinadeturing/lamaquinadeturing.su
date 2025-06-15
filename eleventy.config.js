import { URL } from "url";
import MarkdownIt from "markdown-it";

// 11ty plugins
import { EleventyRenderPlugin as eleventyRenderPlugin } from "@11ty/eleventy";
import eleventyFeedPlugin from "@11ty/eleventy-plugin-rss";

// Custom plugins
import { default as slugifyPlugin, slugify } from "./_plugins/slugify.js";
import l10nPlugin from "./_plugins/l10n.js";
import assetsPlugin from "./_plugins/assets.js";
import { getCategories } from "./_plugins/categories.js";

// Third-party markdown-it plugins
import mdAnchorPlugin from "markdown-it-anchor";
import mdTocPlugin from "markdown-it-table-of-contents";
import mdCenterTextPlugin from "markdown-it-center-text";
import mdFootnotesPlugin from "markdown-it-footnote";
import mdAttrsPlugin from "markdown-it-attrs";
import mdPrismPlugin from "markdown-it-prism";
import mdAttribution from "markdown-it-attribution";
// Custom markdown-it plugins
import mdDecorateLinksPlugin from "./_plugins/decorate_links.js";
import { mdUuidToLinkPlugin } from "./_plugins/l10n.js";
import mdMermaidPlugin from "./_plugins/mermaid.js";
import mdInlineCodePlugin from "./_plugins/inline_code.js";

const languages = ["ca", "en", "es"];

// This is filled while creating the collections... using global data is not recommended,
// but it's the only way to have the data available in the Markdown renderer
// See the comment in the collections section
const uuidToPost = {};

export default async function (eleventyConfig) {
    //= Site settings

    // Use Jekyll's _layout directory for layouts
    eleventyConfig.setLayoutsDirectory("_layouts");

    // Display dates in UTC (so they don't risk being off by one day)
    eleventyConfig.setLiquidOptions({ timezoneOffset: 0 });

    //= Site data

    eleventyConfig.addGlobalData("site", {
        title: "La màquina de Turing",
        description: "cat /dev/random",
        url: "https://lamaquinadeturing.su",
        languages,
        social: {
            mastodon: "@urixturing@mastodont.cat",
            github: "https://github.com/maquinadeturing/lamaquinadeturing.su",
            rss: "/feed.xml",
        }
    });

    const assets = [
        {
            type: "css",
            source: {
                files: ["assets/css/inlined.css"]
            },
            load: "inlined"
        },
        {
            type: "css",
            source: {
                files: [
                    "assets/css/style.css",
                    "assets/css/toc.css" // Linked to avoid CSS `transition` triggered when this file is loaded
                ]
            },
            load: "linked",
            output: "assets/css/linked.css"
        },
        {
            type: "css",
            source: {
                directory: "assets/css"
            },
            load: "deferred",
            output: "assets/css/deferred.css"
        },
        {
            type: "js",
            source: {
                directory: "assets/js"
            },
            load: "deferred",
            output: "assets/js/combined.js"
        },
        {
            type: "media",
            source: {
                directory: "assets/media"
            },
            output: "assets/media",
            sizes: [
                478,
                618,
                698,
                1078,
                { size: 1200, quality: 75 } // OG image
            ],
            format: {
                type: "jpeg",
                quality: 85
            }
        }
    ];

    //= Passthrough
    for (const file of [
        "android-chrome-192x192.png",
        "android-chrome-512x512.png",
        "apple-touch-icon.png",
        "favicon-16x16.png",
        "favicon-32x32.png",
        "favicon.ico",
        "CNAME", // needed by GitHub Pages
    ]) {
        eleventyConfig.addPassthroughCopy(file);
    }

    //= Plugins

    eleventyConfig.addPlugin(eleventyRenderPlugin);
    eleventyConfig.addPlugin(eleventyFeedPlugin);

    eleventyConfig.addPlugin(slugifyPlugin);
    eleventyConfig.addPlugin(l10nPlugin, { languages, localizationPath: "./_data/localization.json" });
    eleventyConfig.addPlugin(assetsPlugin, { assets });

    //= Collections

    eleventyConfig.addCollection("categories", function (collectionApi) {
        // HACK: this resets uuidToPost before it is filled again in the posts collection
        // This is needed when running eleventy --serve, to avoid duplicating entries in uuidToPost
        Object.keys(uuidToPost).forEach(key => delete uuidToPost[key]);

        const categories = getCategories(collectionApi.getFilteredByGlob("./_posts/**/*.md"), eleventyConfig.dir.data);
        const category_map = {};

        for (const category of categories) {
            category_map[category.lang] = category_map[category.lang] || {};
            category_map[category.lang][category.title.toLowerCase()] = category.uuid;
        }

        for (const post of collectionApi.getFilteredByGlob("./_posts/**/*.md")) {
            if (!post.data.categories) continue;

            const lang = post.inputPath.split("/")[2];
            const post_categories = post.data.categories.split(/\s+/);

            const category_uuids = [];

            for (const category of post_categories) {
                let category_uuid = category_map[lang][category.toLowerCase()];
                if (!category_uuid) {
                    throw new Error(`Category ${category} not found for post ${post.url}`);
                }

                category_uuids.push(category_uuid);
            }

            post.data.categories = category_uuids;
        }

        return categories;
    });

    eleventyConfig.addCollection("posts", collectionApi => collectionApi.getFilteredByGlob("./_posts/**/*.md").map(post => {
        const lang = post.inputPath.split("/")[2];
        const uuid = post.data.uuid;

        // See the comment at the top of the file
        uuidToPost[uuid] = uuidToPost[uuid] || {};
        uuidToPost[uuid][lang] = post;

        return post;
    }));

    eleventyConfig.addCollection("posts_by_lang", collectionApi => {
        const posts = Object.entries(uuidToPost).map(([uuid, posts_by_lang]) => {
            return {
                uuid,
                posts: posts_by_lang
            }
        });
        posts.sort((a, b) => {
            const a_date = Math.max(...Object.values(a.posts).map(post => post.date));
            const b_date = Math.max(...Object.values(b.posts).map(post => post.date));
            return b_date - a_date;
        });

        return posts;
    });

    //= Filters

    // Register slugify again to make sure the same logic is available here and in the data layer
    eleventyConfig.addFilter("slugify", slugify);

    eleventyConfig.addFilter("js_object", function (name, data, ...other) {
        const obj = { [name]: data };
        for (let i = 0; i < other.length; i += 2) {
            obj[other[i]] = other[i + 1];
        }
        return obj;
    });

    eleventyConfig.addFilter("absolute_url", function (path) {
        if (path.startsWith("http")) return path;
        return new URL(path, eleventyConfig.globalData.site.url);
    });

    eleventyConfig.addFilter("absolute_path", function (path) {
        if (!path) throw new Error("Path is required");
        if (path.startsWith("http")) return path;
        return new URL(path, eleventyConfig.globalData.site.url).pathname;
    });

    // Markdown

    const mdLib = MarkdownIt()
        .use(mdDecorateLinksPlugin)
        .use(mdUuidToLinkPlugin, { uuidToPost });

    eleventyConfig.addFilter("markdownify", (content, lang) => {
        if (!content) return "";
        return mdLib.render(content, { lang, site: { languages } });
    });

    eleventyConfig.amendLibrary("md", (mdLib) => mdLib
        // Third-party plugins
        .use(mdAttrsPlugin)
        .use(mdAnchorPlugin, { permalink: mdAnchorPlugin.permalink.linkInsideHeader({
            class: "heading-link",
            symbol: "§",
            placement: "after",
        }) })
        .use(mdPrismPlugin)
        .use(mdTocPlugin, { containerClass: "toc", includeLevel: [1, 2, 3] })
        .use(mdCenterTextPlugin)
        .use(mdFootnotesPlugin)
        .use(mdAttribution, { classNameContainer: "quote", classNameAttribution: "quote-citation", marker: "---", removeMarker: true })
        // Custom plugins
        .use(mdDecorateLinksPlugin)
        .use(mdUuidToLinkPlugin, { uuidToPost })
        .use(mdMermaidPlugin)
        .use(mdInlineCodePlugin)
    );
};
