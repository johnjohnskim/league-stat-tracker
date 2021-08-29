import Chart from "chart.js";
import colors from "./colors";
import { parseDataset, formatDuration } from "./utils";

const PlayerChartComponent = {
  mounted() {
    const datasets = Array.from(this.el.children).map((dataset) => {
      const { participantId, label, championIcon, winner } = dataset.dataset;

      return {
        data: Array.from(dataset.children).map(parseDataset),
        label,
        lineTension: 0,
        fill: false,
        pointRadius: 0,
        borderColor: colors.players[participantId],
        backgroundColor: colors.players[participantId],
        context: {
          championName: label,
          championIcon: championIcon,
          winner: winner === "true",
        },
      };
    });

    const maxTime = Math.max(...datasets[0].data.map(({ x }) => x));

    const maxValue = datasets.reduce((acc, dataset) => {
      const max = Math.max(...dataset.data.map(({ y }) => y));
      return Math.max(acc, max);
    }, 0);
    const roundedMax = Math.ceil(maxValue / 2000) * 2000;

    const ctx = this.el.parentElement.querySelector("#chart");
    this.chart = new Chart(ctx, {
      type: "line",
      data: {
        datasets,
      },
      options: {
        scales: {
          xAxes: [
            {
              type: "linear",
              position: "bottom",
              gridLines: {
                color: colors.ticks,
              },
              ticks: {
                min: 0,
                max: maxTime,
                stepSize: 300,
                maxTicksLimit: 8,
                fontColor: colors.labels,
                callback: formatDuration,
              },
            },
          ],
          yAxes: [
            {
              type: "linear",
              position: "left",
              gridLines: {
                color: colors.ticks,
                zeroLineColor: colors.zeroLine,
              },
              ticks: {
                min: 0,
                max: roundedMax,
                stepSize: 1000,
                maxTicksLimit: 11,
                fontColor: colors.labels,
              },
            },
          ],
        },
        tooltips: {
          enabled: false,
          mode: "index",
          intersect: false,
          itemSort: function (a, b) {
            return b.yLabel - a.yLabel;
          },
          callbacks: {
            title: function (items) {
              const seconds = Math.round(items[0].xLabel);
              return formatDuration(seconds);
            },
            label: function (tooltipItem) {
              return tooltipItem.value;
            },
          },
          custom: createCustomTooltip,
        },
        legend: {
          align: "start",
          labels: {
            fontColor: colors.legendFontColor,
          },
        },
      },
      plugins: [
        {
          beforeInit: (chart) => {
            chart.legend.afterFit = function () {
              this.height = this.height + 15;
            };
          },
        },
      ],
    });
  },
  destroyed() {
    this.chart.destroy();
  },
};

function createCustomTooltip(tooltipModel) {
  let tooltipEl = document.getElementById("chartjs-tooltip");

  // Create element on first render
  if (!tooltipEl) {
    tooltipEl = document.createElement("div");
    tooltipEl.id = "chartjs-tooltip";
    tooltipEl.innerHTML = "<table></table>";
    document.body.appendChild(tooltipEl);
  }

  // Hide if no tooltip
  if (tooltipModel.opacity === 0) {
    tooltipEl.style.opacity = 0;
    return;
  }

  // Set caret position
  tooltipEl.classList.remove("above", "below", "no-transform");
  if (tooltipModel.yAlign) {
    tooltipEl.classList.add(tooltipModel.yAlign);
  } else {
    tooltipEl.classList.add("no-transform");
  }

  // Set body
  if (tooltipModel.body) {
    const titleLines = (tooltipModel.title || []).map(
      (title) => `<tr><th class="tooltip__title">${title}</th></tr>`
    );
    const thead = `<thead>${titleLines.join("")}</thead>`;

    const contexts = this._chart.config.data.datasets.map(({ context }) => context);
    const bodyLines = tooltipModel.body
      .map((bodyItem) => bodyItem.lines)
      .map((body, i) => {
        const datasetIndex = tooltipModel.dataPoints[i].datasetIndex;
        const context = contexts[datasetIndex];

        const rowClassMod = context.winner ? "winner" : "loser";

        const tooltipColors = tooltipModel.labelColors[i];
        const styles = {
          "background-color": tooltipColors.backgroundColor,
          "border-color": tooltipColors.borderColor,
        };
        const styleStrings = Object.entries(styles).map(([k, v]) => `${k}: ${v};`);

        return `<tr><td>
          <div class="tooltip__row tooltip__row--${rowClassMod}">
            <span class="tooltip__color-span" style="${styleStrings.join("")}"></span>
            <img
              src="${context.championIcon}"
              alt="${context.championName}"
              title="${context.championName}"
              class="tooltip__icon"
            >
            <span class="tooltip__text">${padString(body[0], 5, "&nbsp;")}</span>
          </div>
        </td></tr>`;
      });
    const tbody = `<tbody>${bodyLines.join("")}</tbody>`;

    const tableRoot = tooltipEl.querySelector("table");
    tableRoot.innerHTML = `${thead}${tbody}`;
  }

  const chartRect = this._chart.canvas.getBoundingClientRect();

  // Set tooltip styles
  const styles = {
    opacity: 1,
    position: "absolute",
    left: `${chartRect.left + chartRect.width}px`,
    top: `${chartRect.top + chartRect.height / 10}px`,
    padding: `${tooltipModel.yPadding}px ${tooltipModel.xPadding}px`,
    fontFamily: tooltipModel._bodyFontFamily,
    fontSize: `${tooltipModel.bodyFontSize}px`,
    fontStyle: tooltipModel._bodyFontStyle,
    color: colors.legendFontColor,
    pointerEvents: "none",
  };

  for (let prop in styles) {
    tooltipEl.style[prop] = styles[prop];
  }
}

function padString(s, length, char) {
  let diff = length - s.length;
  while (diff > 0) {
    s = char + s;
    diff -= 1;
  }
  return s;
}

export default PlayerChartComponent;
