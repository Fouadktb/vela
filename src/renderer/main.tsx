import React from "react";
import { createRoot } from "react-dom/client";
import { App } from "./app/App";
import { PlayerOverlayApp } from "./features/playback/PlayerOverlayApp";
import "./styles/global.css";

const isPlayerOverlay = window.location.hash === "#player-overlay";
document.documentElement.classList.toggle("player-overlay-root", isPlayerOverlay);

createRoot(document.getElementById("root") as HTMLElement).render(
  <React.StrictMode>
    {isPlayerOverlay ? <PlayerOverlayApp /> : <App />}
  </React.StrictMode>
);
