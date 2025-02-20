import fs from 'fs';
import path from 'path';

import deterministicUuidV4 from './deterministic_uuid.js';

import { slugifyUnicode } from './slugify.js';

export const getCategories = (posts, dataDirectory) => {
    const all_categories = loadCategoriesFromPosts(posts);
    const categories_file = path.join(dataDirectory, "category_pages.json");
    const category_pages = JSON.parse(fs.readFileSync(categories_file, "utf-8"));
    const categories_without_page = {};
    const categories = [];
    const all_uuids = new Set(Object.keys(category_pages));

    const findCategoryByName = (category_name, lang) => {
        for (const [uuid, langs] of Object.entries(category_pages)) {
            if (langs[lang].title.toLowerCase() === category_name.toLowerCase()) {
                return uuid;
            }
        }
        return null;
    };

    const getCategoryDescription = (category_uuid, lang) => {
        if (!category_pages[category_uuid]) return "";
        if (!category_pages[category_uuid][lang]) return "";
        return category_pages[category_uuid][lang].description;
    }

    const generateUuid = (category_name) => {
        let category_uuid = null;
        let counter = 0;
        do {
            category_uuid = deterministicUuidV4(`${category_name.toLowerCase()}-${counter++}`);
        } while (all_uuids.has(category_uuid));
        return category_uuid;
    };

    for (const [lang, lang_categories] of Object.entries(all_categories)) {
        for (const category_name of lang_categories) {
            let category_uuid = findCategoryByName(category_name, lang) ||
                categories_without_page[category_name] ||
                null;

            if (!category_uuid) {
                category_uuid = generateUuid(category_name);
                all_uuids.add(category_uuid);
                categories_without_page[category_name] = category_uuid;
            }

            categories.push({
                lang,
                title: category_name,
                uuid: category_uuid,
                description: getCategoryDescription(category_uuid, lang),
                url: `${lang}/${slugifyUnicode(category_name)}/`,
            });
        }
    }

    return categories;
};

function loadCategoriesFromPosts(posts) {
    let all_categories = {};
    for (const post of posts) {
        if (!post.data.categories) continue;
        const categories = post.data.categories.split(/\s+/);

        for (const category of categories) {
            all_categories[post.data.lang] = all_categories[post.data.lang] || new Set();
            all_categories[post.data.lang].add(category);
        }
    }

    return Object.fromEntries(Object.entries(all_categories).map(([lang, categories]) => {
        return [lang, Array.from(categories)];
    }));
}
