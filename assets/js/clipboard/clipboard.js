export function setClipboard(text) {
  navigator.clipboard.writeText(text).then(
    () => {},
    (e) => {
      console.error(e);
    }
  );
}
