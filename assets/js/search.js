var search_index = null;

document.addEventListener('DOMContentLoaded', function() {
    let search_form_element = document.querySelector('.search-form');
    let search_field_element = document.querySelector('.search-field');
    let search_results_element = document.querySelector('.search-results');
    let search_timeout = null;

    document.querySelector('.search-submit').addEventListener('click', async function (e) {
        e.preventDefault();
        submit_search();
    });

    search_field_element.addEventListener('input', function() {
        submit_search();
    });

    document.addEventListener('click', (event) => {
        if (!search_form_element.contains(event.target) && !search_results_element.contains(event.target)) {
            clear_search_results();
        }
    });

    search_field_element.addEventListener('focus', function() {
        submit_search();
    });

    function clear_search_results() {
        search_results_element.innerHTML = '';
        search_results_element.classList.add('hidden');
    }

    function submit_search() {
        var query = search_field_element.value;

        if (search_timeout) {
            clearTimeout(search_timeout);
        }
        search_timeout = setTimeout(async function() {
            clear_search_results();

            if (!query) {
                return;
            }

            let posts = await search_posts(query);

            if (posts.length == 0) {
                return;
            }

            posts.forEach((post_lang_map) => {
                // Within the post group, use the title of the language `page_lang` if it exists.
                if (post_lang_map.has(page_lang)) {
                    var post = post_lang_map.get(page_lang);
                    // Get the links to the posts in other languages, if any
                    var other_langs = [];
                } else {
                    // Take the post in post_lang_map whose language that appears first in the list `site_languages`
                    var post = Array.from(post_lang_map.values()).find((post) => site_languages.includes(post.lang));
                    var other_langs = Array.from(post_lang_map.keys()).filter((lang) => lang != post.lang);
                }

                let search_result_item = document.createElement('li');
                search_result_item.innerHTML = '<a href="' + post.url + '">' + post.title + '</a>';
                if (post.lang != page_lang) {
                    search_result_item.innerHTML += '<a href="' + post.url + '" class="box-shadow lang-code">' + post.lang + '</a>';
                }

                // Append the following HTML for each post in other_langs `<a href="post url" class="box-shadow lang-code">lang</a>`
                other_langs.forEach((lang) => {
                    search_result_item.innerHTML += '<a href="' + post_lang_map.get(lang).url + '" class="box-shadow lang-code">' + lang + '</a>';
                });

                search_results_element.appendChild(search_result_item);
            });

            search_results_element.classList.remove('hidden');
        }, 500);
    }
});

async function search_posts(query) {
    console.log("Searching for: " + query);

    let index = await get_search_index();
    let posts_results = new Map; // { uuid => { "lang" => ..., "title" => ..., "date" => ..., "url" => ..., "score" => ... }, ... }

    word_search = search_word_index(query, index);

    for (var [post_index, words] of word_search) {
        let post = index_data.posts[post_index];
        // console.log("Post index: " + post.title);
        // for (var [word, result] of words) {
        //     console.log("  Word: " + word + " (" + result.count + ", " + Math.round(result.score * 100) + "%)");
        // }
        let total_score = Array.from(words.values()).reduce((acc, score) => acc + score.score, 0);
        // console.log("  Score: " + Math.round(total_score * 100));

        if (!posts_results.has(post.uuid)) {
            posts_results.set(post.uuid, new Map);
        }

        posts_results.get(post.uuid).set(post.lang, {
            lang: post.lang,
            title: post.title,
            date: post.date,
            url: post.url,
            score: total_score
        });
    }

    return Array.from(posts_results.values()).sort((a, b) => {
        let score_a = Array.from(a.values()).map((post) => post.score).reduce((acc, score) => Math.max(acc, score), 0);
        let score_b = Array.from(b.values()).map((post) => post.score).reduce((acc, score) => Math.max(acc, score), 0);
        return score_b - score_a; // Descending order
    }).slice(0, 10);
}

async function get_search_index() {
    if (!search_index) {
        let response = await fetch("/search-index.json");
        if (!response.ok) {
            return null;
        }

        // The search index is a JSON file with the following structure:
        // {
        //     "index": {
        //         lang: [
        //             { word: [ [post_index, count], ... ], ... },
        //             ... ],
        //         ... },
        //     "posts": [
        //         { "url": ..., "title": ..., "date": ..., "lang": ..., "uuid": ... },
        //         ... ]
        // }
        index_data = await response.json();

        console.log("Search index loaded.");

        // Assign the search index to the global variable but
        // replacing the word arrays with a BKTree object for each language.

        search_index = {};
        for (let lang in index_data.index) {
            tree = new BKTree(levenshtein_distance);
            Object.entries(index_data.index[lang]).forEach(([word, posts]) => {
                tree.add(word, posts);
            });
            search_index[lang] = tree;
        }
    }

    return search_index;
}

function search_word_index(query, index) {
    let words = query.split(' ');
    let results = new Map; // { lang: [ Node, ... ], ... }

    // Max distance for each word length
    const get_distance = (word) => Math.min(Math.floor(word.length / 3), 1);

    for (var lang in index) {
        var tree = index[lang];
        words.forEach(function (word) {
            var candidates = tree.search(word, get_distance(word));
            candidates.forEach(function (candidate) {
                if (results.has(lang)) {
                    results.get(lang).push(candidate);
                } else {
                    results.set(lang, [candidate]);
                }
            });
        });
    }

    // Results is a map of language to an array of Node, where its value is [ [post_index, count], ... ].
    // Group the results per post index and count the number of occurrences and their distances.
    // The indexes refer to the post index in search_index["posts"].

    var post_results = new Map; // { post_index: { word: { count: ..., distance: ... }, ... }, ... }
    results.forEach((results, lang) => {
        results.forEach((word_node) => {
            let word = word_node.word;
            var score = word_node.score;
            word_node.value.forEach((result) => {
                var post_index = result[0];
                var count = result[1];

                if (post_results.has(post_index)) {
                    if (post_results.get(post_index).has(word)) {
                        post_results.get(post_index).get(word).count += count;
                    } else {
                        post_results.get(post_index).set(word, { count: count, score: score });
                    }
                } else {
                    post_results.set(post_index, new Map([[word, { count: count, score: score }]]));
                }
            });
        });
    });

    return post_results;
}

class Node {
    constructor(word, value) {
        this.word = word;
        this.value = value;
        this.children = {};
    }
}

class BKTree {
    constructor(distance_func) {
        this.root = null;
        this.distance_func = distance_func;
    }

    add(word, value) {
        if (this.root === null) {
            this.root = new Node(word, value);
        } else {
            let current = this.root;
            while (true) {
                const dist = this.distance_func(word, current.word);
                if (dist in current.children) {
                    current = current.children[dist];
                } else {
                    current.children[dist] = new Node(word, value);
                    break;
                }
            }
        }
    }

    search(word, threshold) {
        if (this.root === null) {
            return [];
        }

        const candidates = [this.root];
        const results = [];

        while (candidates.length > 0) {
            const node = candidates.pop();
            const distance = this.distance_func(word, node.word);
            if (distance <= threshold) {
                let score = 1 - distance / Math.max(word.length, node.word.length);
                results.push({ word: node.word, value: node.value, score: score });
            }

            for (let d = distance - threshold; d <= distance + threshold; d++) {
                if (d in node.children) {
                    candidates.push(node.children[d]);
                }
            }
        }

        return results;
    }
}

function levenshtein_distance(word1, word2) {
    const len1 = word1.length;
    const len2 = word2.length;
    const dp = Array.from({ length: len1 + 1 }, () => Array(len2 + 1).fill(0));

    for (let i = 0; i <= len1; i++) {
        dp[i][0] = i;
    }
    for (let j = 0; j <= len2; j++) {
        dp[0][j] = j;
    }

    for (let i = 1; i <= len1; i++) {
        for (let j = 1; j <= len2; j++) {
            if (word1[i - 1] === word2[j - 1]) {
                dp[i][j] = dp[i - 1][j - 1];
            } else {
                dp[i][j] = 1 + Math.min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]);
            }
        }
    }

    return dp[len1][len2];
}