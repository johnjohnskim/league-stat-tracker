import "../css/app.scss";
import "phoenix_html";

import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import NProgress from "nprogress";

import { TeamChartComponent, PlayerChartComponent } from "./charts";
import { ARAMClipboard } from "./clipboard";

const hooks = {
  TeamChartComponent: TeamChartComponent,
  PlayerChartComponent: PlayerChartComponent,
  ARAMClipboard: ARAMClipboard,
};

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: hooks,
  params: { _csrf_token: csrfToken },
});

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", (info) => NProgress.start());
window.addEventListener("phx:page-loading-stop", (info) => NProgress.done());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket;
