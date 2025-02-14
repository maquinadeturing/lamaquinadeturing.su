import fs from "fs";
import { validate as uuidValidate, version as uuidVersion } from "uuid";

let languages = [];

export default function (eleventyConfig, options = {}) {
    languages = options.languages || [];
    const localizationStrings = loadLocalizationStrings(options.localizationPath);

    eleventyConfig.addFilter("localize", (text, lang) => {
        if (!lang) return text;
        return localizationStrings[text][lang] || text;
    });

    eleventyConfig.addFilter("translation_url", (collection, uuid, lang) => {
        const translated_posts = collection.filter((post) => post.data.uuid === uuid);

        for (const post of translated_posts) {
            if (post.data.lang === lang) {
                return post.url;
            }
        }

        for (const lang of languages) {
            const post = translated_posts.find((post) => post.data.lang === lang);
            if (post) return post.url;
        }

        throw new Error(`No translation found for ${uuid} in ${lang}`);
    });

    eleventyConfig.addFilter("localized_date", localizedDate);

    eleventyConfig.addFilter("get_category_by_uuid", (collection, uuid, lang) => {
        return collection.find((category) => category.uuid === uuid && category.lang === lang);
    });

    eleventyConfig.addFilter("filter_collection_by_lang", (collection, lang) => {
        if (!Array.isArray(collection)) {
            console.log(collection);
            throw new Error("Expected a collection to filter");
        }
        return collection.filter((category) => category.lang === lang);
    });

    eleventyConfig.addFilter("localized_category_posts", function (posts, uuid, lang) {
        if (!uuid || !lang) throw new Error("Missing required parameters");

        let categoryPosts = {};
        for (const post of posts) {
            if (!post.data.categories) continue;

            if (post.data.categories.includes(uuid)) {
                categoryPosts[post.data.uuid] = categoryPosts[post.data.uuid] || {};
                categoryPosts[post.data.uuid][post.data.lang] = post;
            }
        }

        const localizedCategoryPosts = [];
        for (const [uuid, posts] of Object.entries(categoryPosts)) {
            if (posts[lang]) {
                localizedCategoryPosts.push(posts[lang]);
                continue;
            }

            for (const language of languages) {
                if (posts[language]) {
                    localizedCategoryPosts.push(posts[language]);
                    break;
                }
            }
        }

        return localizedCategoryPosts.sort((a, b) => new Date(b.date) - new Date(a.date));
    });

    eleventyConfig.addFilter("translations", function (posts, uuid, lang) {
        const filtered_posts = posts.filter((post) => post.data.uuid === uuid && post.data.lang !== lang);

        const translations = [];
        for (const language of languages) {
            const translation = filtered_posts.find((post) => post.data.lang === language);
            if (translation) translations.push(translation);
        }

        return translations;
    });

    eleventyConfig.addFilter("find_prefered_translation", (post_by_lang, prefered_lang) => {
        if (post_by_lang[prefered_lang]) return post_by_lang[prefered_lang];
        for (const lang of languages) {
            if (post_by_lang[lang]) return post_by_lang[lang];
        }
        throw new Error("No translation found");
    });

    eleventyConfig.addFilter("localized_posts", findLocalizedPosts);
};

function loadLocalizationStrings(jsonPath) {
    if (!jsonPath) return {};
    return JSON.parse(fs.readFileSync(jsonPath));
}

function findLocalizedPosts(posts, lang) {
    const postsMap = {};
    for (const post of posts) {
        postsMap[post.data.uuid] = postsMap[post.data.uuid] || {};
        postsMap[post.data.uuid][post.data.lang] = post;
    }

    // Now choose the post with `lang`, or the next one available following `languages`
    const localizedPosts = [];
    for (const uuid in postsMap) {
        const posts = postsMap[uuid];

        if (posts[lang]) {
            localizedPosts.push(posts[lang]);
            continue;
        }

        for (const language of languages) {
            if (posts[language]) {
                localizedPosts.push(posts[language]);
                break;
            }
        }
    }

    // Sort localizedPosts by date
    localizedPosts.sort((a, b) => new Date(b.date) - new Date(a.date));

    return localizedPosts;
};

function localizedDate(date, format, lang) {
    const dateObject = new Date(date); // Ensure the input is a valid Date object

    if (lang === "ca") {
        const catalanMonthsLong = [
            "gener", "febrer", "març", "abril", "maig", "juny",
            "juliol", "agost", "setembre", "octubre", "novembre", "desembre"
        ];
        const catalanMonthsShort = [
            "gen", "feb", "mar", "abr", "mai", "jun",
            "jul", "ago", "set", "oct", "nov", "des"
        ];

        if (format.includes("%B")) {
            const monthNumber = dateObject.getMonth(); // getMonth() returns 0-based index
            format = format.replace("%B", catalanMonthsLong[monthNumber]);
        }
        if (format.includes("%b")) {
            const monthNumber = dateObject.getMonth();
            format = format.replace("%b", catalanMonthsShort[monthNumber]);
        }
    } else if (lang === "es") {
        const spanishMonthsLong = [
            "enero", "febrero", "marzo", "abril", "mayo", "junio",
            "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
        ];
        const spanishMonthsShort = [
            "ene", "feb", "mar", "abr", "may", "jun",
            "jul", "ago", "sep", "oct", "nov", "dic"
        ];

        if (format.includes("%B")) {
            const monthNumber = dateObject.getMonth();
            format = format.replace("%B", spanishMonthsLong[monthNumber]);
        }
        if (format.includes("%b")) {
            const monthNumber = dateObject.getMonth();
            format = format.replace("%b", spanishMonthsShort[monthNumber]);
        }
    } else if (lang === "en") {
        const englishMonthsLong = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ];
        const englishMonthsShort = [
            "Jan", "Feb", "Mar", "Apr", "May", "Jun",
            "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
        ];

        if (format.includes("%B")) {
            const monthNumber = dateObject.getMonth();
            format = format.replace("%B", englishMonthsLong[monthNumber]);
        }
        if (format.includes("%b")) {
            const monthNumber = dateObject.getMonth();
            format = format.replace("%b", englishMonthsShort[monthNumber]);
        }
    } else {
        throw new Error(`Unsupported language: ${lang}`);
    }

    // Use the modified format for the final output
    const day = String(dateObject.getDate());
    const paddedDay = String(dateObject.getDate()).padStart(2, "0");
    const year = dateObject.getFullYear();

    // Replace additional placeholders (%d, %Y)
    format = format.replace("%d", paddedDay)
        .replace("%-d", day)
        .replace("%Y", year);

    return format;
}

export const mdUuidToLinkPlugin = (md, options) => {
    const uuidToPost = options.uuidToPost;

    const decorateLink = (tokens, idx, options, env, self, defaultRender) => {
        const href = tokens[idx].attrGet("href");

        if (href && uuidValidate(href)) {
            if (uuidVersion(href) !== 4) {
                throw new Error(`Invalid UUID version: ${href}`);
            }

            const post_lang = env.lang;
            const languages = env.site.languages;

            const posts_by_lang = uuidToPost[href];

            if (!posts_by_lang) {
                throw new Error(`No post found for UUID ${href}`);
            }

            let permalink = null;

            if (posts_by_lang[post_lang]) {
                const post = posts_by_lang[post_lang];
                permalink = post.url;
            } else {
                for (const lang of languages) {
                    if (posts_by_lang[lang]) {
                        const post = posts_by_lang[lang];
                        permalink = post.url;
                        break;
                    }
                }
            }

            if (!permalink) {
                throw new Error(`No permalink found for post ${href} in ${post_lang}`);
            }

            tokens[idx].attrSet("href", permalink);
        }

        return defaultRender(tokens, idx, options, env, self);
    };

    const defaultRender = md.renderer.rules.link_open || function (tokens, idx, options, env, self) {
        return self.renderToken(tokens, idx, options);
    };

    md.renderer.rules.link_open = (tokens, idx, options, env, self) => {
        return decorateLink(tokens, idx, options, env, self, defaultRender);
    };
};
