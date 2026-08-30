document.addEventListener("DOMContentLoaded", () => {
  const markers = [...document.querySelectorAll(".backend-example")];

  for (let index = 0; index < markers.length; index += 2) {
    const pair = markers.slice(index, index + 2);
    if (pair.length !== 2) return;

    const tabs = document.createElement("div");
    tabs.className = "backend-tabs";
    const tabList = document.createElement("div");
    tabList.className = "backend-tab-list";
    tabs.append(tabList);
    const markerContainers = pair.map((marker) => marker.closest("p") || marker);
    markerContainers[0].before(tabs);

    const panels = pair.map((marker) => {
      const backend = marker.dataset.backend;
      const button = document.createElement("button");
      button.type = "button";
      button.dataset.backend = backend;
      button.textContent = backend[0].toUpperCase() + backend.slice(1);
      tabList.append(button);

      const panel = markerContainers[pair.indexOf(marker)].nextElementSibling;
      panel.dataset.backend = backend;
      tabs.append(panel);
      markerContainers[pair.indexOf(marker)].remove();
      return panel;
    });
    const buttons = [...tabList.querySelectorAll("button")];

    const select = (backend) => {
      buttons.forEach((button) => {
        button.setAttribute("aria-selected", button.dataset.backend === backend);
      });
      panels.forEach((panel) => {
        panel.hidden = panel.dataset.backend !== backend;
      });
    };

    buttons.forEach((button) => {
      button.addEventListener("click", () => select(button.dataset.backend));
    });
    select("terminal");
  }
});
