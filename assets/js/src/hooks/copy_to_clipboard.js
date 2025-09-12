export default CopyToClipboard = {
  mounted() {
    this.el.addEventListener("click", (event) => {
      event.preventDefault();

      let text = this.el.dataset.clipboardText;
      const selector = this.el.dataset.clipboardSelector;

      if (selector) {
        const element = document.querySelector(selector);
        if (element) {
          text = element.textContent || element.getAttribute("value") || "";
        }
      }

      if (!text) {
        return;
      }

      navigator.clipboard
        .writeText(text)
        .then(() => {
          this.pushEventTo(this.el, "copy-to-clipboard-success", {});
        })
        .catch((err) => {
          this.pushEvent("copy-to-clipboard-error", { error: err.message });
        });
    });
  },
};
