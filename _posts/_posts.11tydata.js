import { slugify } from "../_plugins/slugify.js";
import { v4 as uuidv4 } from "uuid";

export default {
    eleventyComputed: {
        permalink: (data) => {
            const lang = data.page.inputPath.split("/")[2];

            const date = new Date(data.date);
            const title = data.title;

            const year = date.getFullYear();
            const month = String(date.getMonth() + 1).padStart(2, "0");
            const slug = slugify(title, { lower: true, strict: true });

            return `${lang}/${year}/${month}/${slug}/`;
        },
        lang: (data) => data.page.inputPath.split("/")[2],
        uuid: (data) => data.uuid || uuidv4(),
        layout: (data) => data.layout || "post",
    }
}