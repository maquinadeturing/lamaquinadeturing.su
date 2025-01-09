import slugifyLib from "slugify";

export default function (eleventyConfig, pluginOptions = {}) {
  eleventyConfig.addFilter("slugify-utf8", slugifyUnicode);
}

export const slugify = (value) => {
  return slugifyLib(value, { lower: true, strict: true });
};

export const slugifyUnicode = (value) => {
  return value.toLowerCase().replace(/\s+/g, "-");
}
