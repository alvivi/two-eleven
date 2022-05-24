import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

import topbar from "../vendor/topbar";

/*
 * TopBar
 */

const topbarDelayInMs = 100;
let loadingHandler = null;

topbar.config({
  barColors: { 0: "#f97316" },
  shadowColor: "rgba(0, 0, 0, .3)",
});

window.addEventListener("phx:page-loading-start", (info) => {
  if (loadingHandler === null) {
    loadingHandler = setTimeout(() => topbar.show(), topbarDelayInMs);
  }
});

window.addEventListener("phx:page-loading-stop", (info) => {
  clearTimeout(loadingHandler);
  loadingHandler = null;
  topbar.hide();
});

// Phoenix Hooks

let Hooks = {};

// Phoenix Hooks - Game Board

Hooks.GameBoard = {
  transitionDuration: 75,
  tileSide: 90,
  colors: {
    2: "",
    4: "!bg-yellow-600",
    8: "!bg-orange-600",
    16: "!bg-red-400",
    32: "!bg-red-600",
    64: "!bg-teal-400",
    128: "!bg-teal-600",
    256: "!bg-sky-400",
    512: "!bg-sky-500",
    1024: "!bg-violet-400",
    2048: "!bg-violet-600",
    4096: "!bg-rose-400",
    8192: "!bg-rose-600",
  },

  mounted() {
    this.handleEvent("apply-board-events", this.applyBoardEvents.bind(this));
    this.updated();
  },

  updated() {
    this.width = this.el.dataset.boardWidth;
    this.height = this.el.dataset.boardHeight;

    this.el.replaceChildren();
    this.appendSlots();
    this.tiles = new Map();
  },

  applyBoardEvents(payload) {
    payload.events.forEach((event) => {
      let tile, obstacle, span, x, y, tile_width, tile_height;

      switch (event.type) {
        case "obstacle-placed":
          [tile_width, tile_height] = this.getTileSize();
          [x, y] = this.getTileTranslation(event.to.x, event.to.y);
          obstacle = document.createElement("div");
          obstacle.classList.add("board-obstacle");
          obstacle.style.transform = `translate(${x}%, ${y}%)`;
          obstacle.style.width = `${tile_width}%`;
          obstacle.style.height = `${tile_height}%`;
          this.el.appendChild(obstacle);
          break;

        case "tile-merged":
          tile = this.getTile(event.from);
          [x, y] = this.getTileTranslation(event.to.x, event.to.y);
          tile.style.transform = `translate(${x}%, ${y}%)`;

          setTimeout(() => {
            tile.parentElement.removeChild(tile);
            tile = this.getTile(event.to);
            tile.children[0].textContent = event.value;
            tile.className = `board-tile ${this.colors[event.value]}`;
          }, this.transitionDuration);

          break;

        case "tile-moved":
          tile = this.getTile(event.from);
          [x, y] = this.getTileTranslation(event.to.x, event.to.y);
          tile.style.transform = `translate(${x}%, ${y}%)`;
          this.deleteTile(event.from);
          this.setTile(event.to, tile);

          break;

        case "tile-placed":
          [tile_width, tile_height] = this.getTileSize();
          [x, y] = this.getTileTranslation(event.to.x, event.to.y);
          span = document.createElement("span");
          span.classList.add("board-tile-content");
          span.textContent = event.value;
          tile = document.createElement("div");
          tile.appendChild(span);
          tile.className = `board-tile ${this.colors[event.value]}`;
          tile.style.transform = `translate(${x}%, ${y}%)`;
          tile.style.width = `${tile_width}%`;
          tile.style.height = `${tile_height}%`;
          this.el.appendChild(tile);
          this.setTile(event.to, tile);

          break;
      }
    });
  },

  appendSlots() {
    const [tile_width, tile_height] = this.getTileSize();

    for (let j = 0; j < this.height; j++) {
      for (let i = 0; i < this.width; i++) {
        const [x, y] = this.getTileTranslation(i, j);
        const slot = document.createElement("div");
        slot.classList.add("board-slot");
        slot.style.transform = `translate(${x}%, ${y}%)`;
        slot.style.width = `${tile_width}%`;
        slot.style.height = `${tile_height}%`;
        this.el.appendChild(slot);
      }
    }
  },

  getTileSize() {
    return [this.tileSide / this.width, this.tileSide / this.height];
  },

  getTileTranslation(tile_x, tile_y) {
    const x_space_between = (100 * this.width) / (this.width + 1);
    const y_space_between = (100 * this.height) / (this.height + 1);
    const norm_y = this.height - tile_y - 1;
    const x = x_space_between * (tile_x + 1) + tile_x * 100;
    const y = y_space_between * (norm_y + 1) + norm_y * 100;

    return [x, y];
  },

  getTile({ x, y }) {
    return this.tiles.get(x + y * this.width);
  },

  setTile({ x, y }, tile) {
    this.tiles.set(x + y * this.width, tile);
  },

  deleteTile({ x, y }) {
    this.tiles.delete(x + y * this.width);
  },
};

// Phoenix Hooks - Chat Message List

Hooks.ChatMessageList = {
  updated() {
    if (this.el.children.length > 0) {
      const lastChild = this.el.children[this.el.children.length - 1];
      lastChild.scrollIntoView({ block: "end", inline: "start" });
    }
  },
};

// Phoenix Window Event Handlers

window.addEventListener("phx:focus", (payload) => {
  const target = document.querySelector(payload.detail.selector);

  if (target) {
    target.focus();
  }
});

/*
 * LiveSocket
 */

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
});

liveSocket.connect();

window.liveSocket = liveSocket;
