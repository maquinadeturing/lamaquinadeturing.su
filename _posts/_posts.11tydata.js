import { slugify } from "../_plugins/slugify.js";
import deterministicUuidV4 from "../_plugins/deterministic_uuid.js";

export default {
    eleventyComputed: {
        permalink: (data) => getPermalink(data),
        lang: (data) => data.page.inputPath.split("/")[2],
        uuid: (data) => getUuid(data),
        layout: (data) => data.layout || "post",
    }
}

function getUuid(input) {
    if (input.uuid) {
        return input.uuid;
    }
    const permalink = getPermalink(input);

    // This is a deterministic UUID v4 based on the permalink
    // There is a non-zero chance of collision, but it's *very* low
    return deterministicUuidV4(permalink);
}

function getPermalink(data) {
    if (data.permalink) {
        return data.permalink;
    }

    const lang = data.page.inputPath.split("/")[2];

    const date = new Date(data.date);
    const title = data.title;

    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const slug = slugify(title, { lower: true, strict: true });

    return `${lang}/${year}/${month}/${slug}/`;
}
