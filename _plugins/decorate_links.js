export default (md, options) => {
    const decorateLink = (tokens, idx, options, env, self, defaultRender) => {
        const href = tokens[idx].attrGet("href");

        if (href && href.match(/^https?:\/\/.+/)) {
            const url = new URL(href);

            if (url.pathname.startsWith("/@")) {
                tokens[idx].attrJoin("class", "link-mastodon");
            } else {
                const top_domain = url.hostname.split(".").slice(-2).join(".");

                switch (top_domain) {
                    case "wikipedia.org":
                    case "wikimedia.org":
                    case "wiktionary.org":
                    case "wikisource.org":
                        tokens[idx].attrJoin("class", "link-wikipedia");
                        break;
                    case "archive.org": tokens[idx].attrJoin("class", "link-archive"); break;
                    case "github.com": tokens[idx].attrJoin("class", "link-github"); break;
                    default: tokens[idx].attrJoin("class", "link-external"); break;
                }
            }
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
