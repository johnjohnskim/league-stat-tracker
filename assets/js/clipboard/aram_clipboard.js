import { setClipboard } from "./clipboard";

const ARAMClipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      navigator.permissions.query({ name: "clipboard-write" }).then((result) => {
        if (result.state == "granted" || result.state == "prompt") {
          const text = document.querySelector("#aram-id-input").value;
          setClipboard(text);
        }
      });
    });
  },
};

export default ARAMClipboard;
