export default (md, options) => {
    const decorateLink = (tokens, idx, options, env, self, defaultRender) => {
        const href = tokens[idx].attrGet("href");

        if (href && href.match(/^https?:\/\/.+/)) {
            const addClass = (newClass) => {
                const classValue = tokens[idx].attrGet("class");
                const classes = classValue ? classValue.split(/ +/) : [];
                classes.push(newClass);
                tokens[idx].attrSet("class", classes.join(" "));
            }

            const url = new URL(href);

            if (url.pathname.startsWith("/@")) {
                addClass("link-mastodon");
            } else {
                const top_domain = url.hostname.split(".").slice(-2).join(".");

                switch (top_domain) {
                    case "wikipedia.org":
                    case "wikimedia.org":
                    case "wiktionary.org":
                    case "wikisource.org":
                        addClass("link-wikipedia");
                        break;
                    case "archive.org": addClass("link-archive"); break;
                    case "github.com": addClass("link-github"); break;
                    default: addClass("link-external"); break;
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
