// Renders assets/icon.svg to assets/icon.png (1024x1024). Needs `npm i sharp` somewhere on the path:
//   node tool/render_icon.js
const sharp = require("sharp");
const path = require("path");
const root = path.join(__dirname, "..", "assets");
sharp(path.join(root, "icon.svg"), { density: 72 })
  .resize(1024, 1024)
  .png()
  .toFile(path.join(root, "icon.png"))
  .then(() => console.log("assets/icon.png written"));
