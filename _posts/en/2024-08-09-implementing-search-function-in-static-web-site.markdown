---
title:  Implementing the search function in a static web site
date:   2024-08-09 13:00:00 +0200
image:  search.jpg
image_caption: "Cuff's solar microscope in [\"Mikroskopische Gemüths - und Augen-Ergötzung\"](https://publicdomainreview.org/collection/microscopic-delights/), vol. 3, by M. F. Ledermüller (1759–63)."
categories: Web
---

Static web sites are the best. They are fast, lightweight, safe and content-centric. However, not having a server comes with its sacrifices. I can go without forms, user accounts or comments, but the thing I miss the most is _searching_.

## The poor man's search function

Usually, the alternative has been the `site:` operator in Google: a form in your website would transform the search string into a `site:` query and redirect it to Google. Purists can do the same with [DuckDuckGo](https://duckduckgo.com/duckduckgo-help-pages/results/syntax/). But that leaves me relying on notoriously unreliable companies, which can drop this feature at any moment or hide it behind a pawyall.

And I wandered: is there a way to have my own search function?

## Is static search even possible?

My wishlist for a search function was:
1. Doesn't depend on an external API.
2. Has to be lightweight, ie. downloading all the posts and searching them is not an option.
3. Has to be reasonably good at finding results, but not perfect. For instance, I can do without full-text search.

With that in mind, I started designing my own static search function. The basic idea was to generate some kind of index that would allow for static searches using Javascript.

There are some nice Javascript libraries that will consume texts and provide a search function, like [Lunr](https://lunrjs.com). It even lets you [pre-build the serch index](https://lunrjs.com/guides/index_prebuilding.html), so it can be downloaded as a static JSON file. As a test, I created a Lunr JSON index with [the](1f8fbc0d-7856-4f82-9cf1-19b2738e90fd/es) [three](8a9feaca-9e90-4c16-b91d-0230b5502fd9/es) [posts](b68e41e8-9b96-4f53-92d0-7c831298858c/es) in Spanish in the blog, as they are the longest right now. The result is the following:

| Posts    | Rendered Post Size[^1] | Lunr JSON Index Size |
| -------- | ------------------ | -------------------- |
| [Post 1](1f8fbc0d-7856-4f82-9cf1-19b2738e90fd/es) | 2.72 KB | 12.39 KB |
| [Post 2](8a9feaca-9e90-4c16-b91d-0230b5502fd9/es) | 87.16 KB | 141.89 KB |
| [Post 3](b68e41e8-9b96-4f53-92d0-7c831298858c/es) | 3.27 KB | 15.04 KB |
| All three posts | 93.16 KB | 158.32 KB |

As it can be seen, the Lunr index grows linearly to the size of the text, but also it becomes larger than the text itself! At least for this small amount of content, it would be better to just download the text of the posts.

Maybe Lunr was too fancy for me, so I should implement my own search library.

## Putting it down in words

The basic functionality of a search function is to map a query to posts that contain them. So a very initial implementation would be to collect all the words from all the posts and map each one to a list of posts. Then, when the user enters a query, the words of such query can be found in the search index.

As this site uses Jekyll, the static generation of the index would be in Ruby, while the search of the index would be in Javascript. Let's focus on the former.

I'll show some snippets of code, but they are greatly simplified and are not expected to actually run:

{% highlight ruby %}
index = {}
site.posts.docs.each do |post|
    rendered_content = site
        .liquid_renderer
        .file(post.path)
        .parse(post.content)
        .render(site.site_payload)
    html_content = site
        .find_converter_instance(Jekyll::Converters::Markdown)
        .convert(rendered_content)

    text_content = html_content.gsub(/<\/?[^>]*>/, ' ')
    ...
{% endhighlight %}

In this iterator, the posts of the site are programmatically rendered using the Liquid parser and the Markdown converter to HTML. The result is the HTML as it would be displayed by the web browser. Then, the HTML tags are stripped, so what remains is the pure text content.

Let's get the words:

{% highlight ruby %}
    ...
    lang = post.data['lang']
    valid_chars = 'a-zA-Z0-9áéíóúàèìòùäëïöüâêîôûçñÁÉÍÓÚÀÈÌÒÙÄËÏÖÜÂÊÎÔÛÇÑ·'

    text_content = text_content.gsub(/[^#{valid_chars}]/, ' ')

    words = text_content.downcase.split(/\s+/)
        .filter { |word| word.length > 1 }
        .filter { |word| !word.match?(/^\d+$/) }
        .filter { |word| !stopwords[lang].include?(word) }
        .sort
        .uniq
    ...
{% endhighlight %}

Here the `text_content` string is filtered, excluding anything that is not a valid character in one of the languages of the blog. This means that punctuation marks or other symbols are removed.

Then, the resulting string is split by words, excluding short ones or numbers. A list of stopwords for the language of the post is used to remove common words, like "then" or "one". There are projects that maintain lists of stopwords, like [NLTK](https://github.com/nltk/nltk_data/blob/gh-pages/packages/corpora/stopwords.zip).

Finally, the words are sorted and duplicates are removed. Great! This is the list of unique words from one post, after removing garbage like stopwords, short words or numbers. Let's add them to the index:

{% highlight ruby %}
    ...
    words.each do |word, count|
        index[lang] ||= {}
        index[lang][word] ||= []
        index[lang][word] << post_index
    end
end
{% endhighlight %}

Note that per each word in a given language, it maps to a list of posts referenced by an "index". This index is the position in the array of posts at the end of the index structure.

Let's use an example. The following snippet is taken from the Markdown source of this [post](28623ef9-070a-464c-889c-f5a42fac3cd4/en):

`**Cybernetics**[^1], the science of the common features of processes and control systems in technological devices, living organisms and human organisations. The principles of C. were first set forth by Wiener (q.v.)`

After rendering it:

`<p><strong>Cybernetics</strong><sup id="fnref:1" role="doc-noteref"><a href="#fn:1" class="footnote" rel="footnote">1</a></sup>, the science of the common features of processes and control systems in technological devices, living organisms and human organisations. The principles of C. were first set forth by Wiener (q.v.).<p>`

After removing the HTML tags:

`Cybernetics 1, the science of the common features of processes and control systems in technological devices, living organisms and human organisations. The principles of C. were first set forth by Wiener (q.v.).`

Removing the invalid characters:

`Cybernetics 1 the science of the common features of processes and control systems in technological devices living organisms and human organisations The principles of C were first set forth by Wiener q v`

And after filtering out short words, numbers and stopwords:

`Cybernetics science common features processes control systems technological devices living organisms human organisations principles set forth Wiener`

Last step, sorting and removing repeated words:

`common control cybernetics devices features forth human living organisations organisms principles processes science set systems technological wiener`

From this, the index would look as follows:

{% highlight json %}
{
    "index": {
        "en": {
            "common": [0],
            "control": [0],
            "cybernetics": [0],
            "devices": [0],
            "features": [0],
            "forth": [0],
            "human": [0],
            "living": [0],
            "organisations": [0],
            "organisms": [0],
            "principles": [0],
            "processes": [0],
            "science": [0],
            "set": [0],
            "systems": [0],
            "technological": [0],
            "wiener": [0],
        }
    },
    "posts": [
        {
            "url": "/en/2024/07/cybernetics-in-a-Dictionary-of-philosophy-1967/",
            "title": "“Cybernetics” (in A Dictionary of Philosophy, 1967)",
            "date": "2024-07-27 19:00:00 +0200",
            "lang": "en"
        }
    ]
}
{% endhighlight %}

The current JSON search index in this format for the 7 posts in 3 languages of the site is 52 KB. Not bad compared to the 141 KB of Lunr for just 3 posts. All in all, 50 KB or 140 KB may be are not very important nowadays, as some images in this site are larger than that. But I'd like this blog to grow enough so the size of the index matters.

## Wait, doesn't that look like a Bloom filter?

Indeed, why not use a [Bloom filter](https://en.wikipedia.org/wiki/Bloom_filter), instead of a map of words? After all, a Bloom filter is super compact: 1 bit per word!

The issue is that a Bloom filter only tells you if a given entry is (probably) part of a set. In other words, it maps a given key to a _boolean value._ But in my case each key must map to a _list of values,_ the posts that contain that word.

There are two alternatives. One is to implement a Bloom filter per post. But that would be prohibitive as the number of posts grows. The other is to implement a modified Bloom filter that can store _values._

Some kind of _Bloom map._

Each entry in the Bloom table would be a set, containing the values that were assigned by the hash functions. Then, the test operation would return the subset of values present in all the entries mapped by the key, if any.

As far as I know, no such hybrid between a Bloom filter and a hash table exists. Maybe for a reason? I am not 100% sure if this would really preserve the accuracy of a Bloom filter, but I made a quick implementation. The result is that even using very compact encodings of this Bloom map (I'm talking about base 36 indices for sparse tables) it still would be less efficient than the previous approach that just stores the list of words. In particular, the Bloom maps would need 82 KB, compared to the 52 KB of the word map.

I'll leave that implementation in a branch. Maybe, in the long run, it outperforms the word map.

## Levenshtein and his friends Burkhard and Keller

Now that the search index is generated, it's time to do some searching in the web browser.

The search index contains (almost) all the words of the posts. A trivial approach would be to take the search query word by word and try to match it against the index. Every time there is a match, one point is given to the matched posts. If the query has 4 words, then the maximum score would be 4. The matching posts are displayed sorted by their score.

{% highlight javascript %}
function search(query, word_map) {
  const query_words = [... new Set(
    to_ansi(query)
    .toLowerCase()
    .split(/\s+/)
  )];
  let results = new Map;
  index.forEach((lang, word_map) => {
    query_words.forEach((query_word) => {
      const posts = word_map.get(query_word);
      if (posts) {
        posts.forEach((post_index) => {
          let score = results.get(post_index) || 0;
          results.set(post_index, score + 1);
        });
      }
    });
  });
  return results;
}
{% endhighlight %}

That will be the base search algorithm, but I would like it to be slightly smarter than that. After all, we are all used to fancy search engines that will find similar words, or match just prefixes. Instead of doing an exact match of the words in the index, the search could find _similar_ words. An obvious optimization is to ignore accents. But how to match other similarities? For instance, "cybernetics" is very similar to "cibernètica" (Catalan).

Enter Levenshtein.

The _similarity_ between two words could be defined as the _distance_ between these words. This is what the [Levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance) function does: it calculates how far away two words are. The distance is defined as how many letters need to be added, removed or substituted to go from one word to the other. In the case of "cybernetics", it needs 2 substitutions to become "cibernètica", if we ignore the accents.

{% highlight javascript %}
function search(query, word_map) {
  const query_words = [... new Set(
    to_ansi(query)
    .toLowerCase()
    .split(/\s+/)
  )];
  let results = new Map;
  index.forEach((lang, word_map) => {
    query_words.forEach((query_word) => {
      const max_distance = Math.max(Math.floor(query_word.length / 3), 1);
      word_map.forEach((posts, index_word) => {
        const distance = levenshtein_distance(query_word, index_word);
        if (distance <= max_distance) {
          posts.forEach((post_index) => {
              const score = 1 - distance / Math.max(query_word.length, index_word.length);
              results.set(post_index, (results.get(post_index) || 0) + score);
          });
        }
      });
    });
  });
  return results;
}
{% endhighlight %}

Good, we now have a precise definition of similarity. So the search algorithm can match not only exact words from the index, but also similar words whose Levenshtein distance is below a certain threshold (in particular, the maximum distance allowed is 1/3 of the length of the word, in other words, two words should share 2/3 of their letters to be considered similar).

Also, now the score is not 1 per each match, because matches may be similar but not exact. How exact? The normalized distance between the words, meaning a distance of 1 in a 5-letter word is an 80% similarity.

But there is another difference between this code and the previous one: before it was using a map to find exact matches, which is fast, while now it is comparing each word from the query to each word from the index. It has gone from O(1) to O(n<sup>2</sup>)![^2]

Let's bring some friends of Levenshtein to the party. In particular, Burkhard and Keller and their tree structure, the [BK-Tree](https://en.wikipedia.org/wiki/BK-tree). A BK-Tree is a data structure that can organize values based on their relative distance, and allows to quickly navigate it to find the values with a similarity below the given threshold.

{% highlight javascript %}
function build_forest(word_map) {
  let forest = new Map;
  index.forEach((lang, word_map) => {
    let tree = new BKTree(levenshtein_distance);
    word_map.forEach((posts, index_word) => {
      tree.add(index_word, posts);
    });
    forest.set(lang, tree);
  });
  return forest;
}

function search(query, word_map) {
  const query_words = [... new Set(
    to_ansi(query)
    .toLowerCase()
    .split(/\s+/)
  )];

  let forest = build_forest(word_map);
  let results = new Map;

  forest.forEach((tree) => {
    query_words.forEach((query_word) => {
      const max_distance = Math.max(Math.floor(query_word.length / 3), 1);
      tree.search(query_word, max_distance).forEach((search_result) => {
        search_result.value.forEach((post_index) => {
          const score = search_result.score;
          results.set(post_index, (results.get(post_index) || 0) + score);
        });
      });
    });
  });
  return results;
}
{% endhighlight %}

In this new code, a BK-Tree is constructed for each word index, and now these trees can be used to search for similar words below a certain threshold with a time complexity of O(log n). That's more like it.

## Looking for the headline

The fuzzy search function that was implemented above will match similar words. But surely the user, after typing "cyber", will expect [28623ef9-070a-464c-889c-f5a42fac3cd4] to appear in the results.

Implementing a prefix match for all the words is possible, for instance with a [radix tree](https://en.wikipedia.org/wiki/Radix_tree) structure. But that would probably generate too many results, many of them unuseful. If the user types "app", do they want results about applications but also about apples?

Still, what is overkill for the content can be adequate if limited to the title. In addition to the score provided by the fuzzy search with the word map, I also added a substring search:

{% highlight javascript %}
function search_titles(query, post_list) {
  const query_words = [... new Set(
    to_ansi(query)
    .toLowerCase()
    .split(/\s+/)
  )];

  let results = new Map;
  for (let i = 0; i < post_list.length; i++) {
    let title = post_list[i].title;
    let score = 0;
    query_words.forEach((query_word) => {
      if (title.includes(word)) {
        score += 1;
      }
    });

    if (score > 0) {
      results.set(i, score);
    }
  }
  return results;
}
{% endhighlight %}

The previous code takes the words of the search query and checks if they are a substring of a post title. For each word that is a substring of a title, that post gets 1 point. The score of the title search is added to the score of the fuzzy search, and that is how posts are displayed in the search box and how they are sorted.

## Conclusion

I am quite satisfied with the static search function I implemented for this website. It is quite lightweight: 52 KB, compared to the 141 KB of Lunr or the 82 KB of a _Bloom map._ Still, the search experience feels similar to what can be expected from a full text search. Go ahead and test it yourself.

Obviously, searching web pages is complicated, after all Google was built around this. If I type for "levens" I want the search function to return me results for Levenshtein, but that will not happen as it is too dissimilar (45% similarity). And yet, it will match "leaves" and "even" (66% similarity).

As the blog grows, maybe I will have to revisit the implementation in case the index becomes too heavy, or it is not very accurate, but for now does the job.

## Notes

[^1]: The count of visible characters of the post's text, as seen in the web browser, excluding white spaces.

[^2]: See [Big O Notation](https://en.wikipedia.org/wiki/Big_O_notation). Also, technically, it has gone from O(1) to O(n m).