import Chart from "chart.js";
import colors from "./colors";
import { parseDataset, formatDuration } from "./utils";

const TeamChartComponent = {
  mounted() {
    const goldData = Array.from(this.el.children[0].children).map(parseDataset);
    const expData = Array.from(this.el.children[1].children).map(parseDataset);

    const maxTime = Math.max(...goldData.map(({ x }) => x));

    const maxGoldValue = Math.max(...goldData.map(({ y }) => Math.abs(y)));
    const maxExpValue = Math.max(...expData.map(({ y }) => Math.abs(y)));
    const roundedMax = Math.ceil(Math.max(maxGoldValue, maxExpValue) / 2000) * 2000;

    const ctx = this.el.parentElement.querySelector("#chart");
    this.chart = new Chart(ctx, {
      type: "line",
      data: {
        datasets: [
          {
            data: goldData,
            label: "Net Worth",
            lineTension: 0,
            pointRadius: 0,
            fill: false,
            borderColor: colors.goldLine,
            backgroundColor: colors.goldLine,
          },
          {
            data: expData,
            label: "Exp",
            lineTension: 0,
            pointRadius: 0,
            fill: false,
            borderColor: colors.expLine,
            backgroundColor: colors.expLine,
          },
        ],
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
                min: -roundedMax,
                max: roundedMax,
                stepSize: 2000,
                maxTicksLimit: 15,
                fontColor: colors.labels,
              },
            },
          ],
        },
        tooltips: {
          mode: "index",
          intersect: false,
          backgroundColor: colors.tooltipBackgroundColor,
          callbacks: {
            title: function (items) {
              const seconds = Math.round(items[0].label);
              return formatDuration(seconds);
            },
          },
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

export default TeamChartComponent;
