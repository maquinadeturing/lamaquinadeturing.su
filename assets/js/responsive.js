document.addEventListener("DOMContentLoaded", function () {
    const nav_toggle_element = document.querySelector("#nav-toggle");
    nav_toggle_element.addEventListener("click", (e) => {
        nav_toggle_element.classList.toggle("active");
        e.preventDefault();
    });

    document.querySelector(".nav-slide-button").addEventListener("click", (e) => {
        e.preventDefault();
        document.querySelectorAll(".pull").forEach((el) => {
            if (!el.style.display || el.style.display == "none") {
                el.style.display = "flex";
            } else {
                el.style.display = "none";
            }
        });
    });
});
