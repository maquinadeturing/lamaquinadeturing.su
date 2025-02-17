export default function markdownItInlineCodeClass(md) {
    const defaultInlineCode = md.renderer.rules.code_inline || function (tokens, idx, options, env, self) {
        return self.renderToken(tokens, idx, options);
    };

    md.renderer.rules.code_inline = function (tokens, idx, options, env, self) {
        tokens[idx].attrJoin("class", "inline");
        return defaultInlineCode(tokens, idx, options, env, self);
    };
}
