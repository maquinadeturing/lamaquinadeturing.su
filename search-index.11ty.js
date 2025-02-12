import fs from "fs";
import path from "path";

const STOP_WORDS_DIR = "./_plugins/stopwords";
const VALID_CHARS = "a-zA-Z0-9áéíóúàèìòùäëïöüâêîôûçñÁÉÍÓÚÀÈÌÒÙÄËÏÖÜÂÊÎÔÛÇÑ·";

class SearchIndex {
    data() {
        return {
            permalink: "/search-index.json",
            eleventyExcludeFromCollections: true
        };
    }

    async render({ collections }) {
        const stopWords = getStopWords();
        const invalidCharsRegex = new RegExp(`[^${VALID_CHARS}]`, "gu");

        const searchIndex = {};
        const postTable = [];

        collections.posts.forEach(post => {
            const lang = post.data.lang;
            const langStopWords = stopWords[lang];

            if (!langStopWords) {
                throw new Error(`Stop words not found for language ${lang}`);
            }

            const words = Array.from(new Set(post.content
                // Remove SVGs
                .replace(/<svg[^>]*?>.*?<\/svg>/g, " ")
                // Remove HTML
                .replace(/<[^>]+>/g, " ")
                // Remove UUIDs
                .replace(/[a-zA-Z0-9]{8}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{12}/g, " ")
                .replace(invalidCharsRegex, " ")
                .toLowerCase()
                .split(/\s+/)
                .filter(
                    word => word.length > 1 &&
                    !langStopWords.has(word) &&
                    !word.match(/^\d+$/)
                )
            ));

            if (words.length === 0) {
                return;
            }

            const postIndex = postTable.length;
            postTable.push({
                url: post.url,
                title: post.data.title,
                date: post.date,
                lang: lang,
                uuid: post.data.uuid,
            });

            words.forEach(word => {
                searchIndex[lang] = searchIndex[lang] || {};

                if (searchIndex[lang][word] === undefined) {
                    searchIndex[lang][word] = postIndex;
                } else if (Array.isArray(searchIndex[lang][word])) {
                    searchIndex[lang][word].push(postIndex);
                } else {
                    searchIndex[lang][word] = [searchIndex[lang][word], postIndex];
                }
            });
        });

        const indexObject = {
            index: sortKeys(searchIndex),
            posts: postTable,
        };

        return JSON.stringify(indexObject);
    }
}

function sortKeys(obj) {
    if (!obj || typeof obj !== "object" || Array.isArray(obj)) {
        return obj;
    }

    return Object.keys(obj).sort().reduce((acc, key) => {
        acc[key] = sortKeys(obj[key]);
        return acc;
    }, {});
}

function getStopWords() {
    const stopWords = {};

    fs.readdirSync(STOP_WORDS_DIR).forEach(file => {
        const filePath = path.join(STOP_WORDS_DIR, file);
        const words = JSON.parse(fs.readFileSync(filePath, "utf-8"));
        const lang = path.basename(file, ".json");
        stopWords[lang] = new Set(words);
    });

    return stopWords;
}

export default SearchIndex;
