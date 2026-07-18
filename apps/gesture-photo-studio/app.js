(function () {
  const fileInput = document.getElementById("fileInput");
  const toggleCamBtn = document.getElementById("toggleCam");
  const toggleDemoBtn = document.getElementById("toggleDemo");
  const startCalibrationBtn = document.getElementById("startCalibration");
  const calibrationStatus = document.getElementById("calibrationStatus");
  const undoBtn = document.getElementById("undoBtn");
  const redoBtn = document.getElementById("redoBtn");
  const resetBtn = document.getElementById("resetBtn");
  const gestureLabel = document.getElementById("gestureLabel");
  const confidenceLabel = document.getElementById("confidenceLabel");
  const confidenceBar = document.getElementById("confidenceBar");
  const cursorLabel = document.getElementById("cursorLabel");
  const comboLabel = document.getElementById("comboLabel");
  const motionSensitivityInput = document.getElementById("motionSensitivity");
  const stabilityInput = document.getElementById("stability");
  const minConfidenceInput = document.getElementById("minConfidence");
  const canvas = document.getElementById("editorCanvas");
  const camPreview = document.getElementById("camPreview");
  const debugCanvas = document.getElementById("debugCanvas");
  const ctx = canvas.getContext("2d");
  const debugCtx = debugCanvas.getContext("2d");

  const state = {
    image: null,
    edit: {
      zoom: 1,
      rotation: 0,
      panX: 0,
      panY: 0,
      brightness: 0,
      contrast: 1,
      saturation: 1,
      exposure: 0,
      temperature: 0,
      sharpness: 0
    },
    history: [],
    future: [],
    gesture: "none",
    confidence: 0,
    cursor: { x: 0.5, y: 0.5 },
    last: null,
    camOn: false,
    demo: false,
    lockUntil: 0,
    hand: null,
    smoothedHand: null,
    handsEngine: null,
    cameraEngine: null,
    combo: "aucun",
    candidateCombo: "aucun",
    candidateSince: 0,
    lastTs: 0,
    calibration: {
      running: false,
      startTs: 0,
      durationMs: 5000,
      samples: [],
      pinchSamples: []
    }
  };

  const tuning = {
    handSmooth: 0.35,
    cursorSmoothSlow: 0.14,
    cursorSmoothFast: 0.35,
    gestureDebounceMs: 120,
    minConfidence: 0.52,
    deadZone: 0.0025,
    maxDeltaPerFrame: 0.03,
    pinchDeadZone: 0.002
  };

  function updateTuningFromInputs() {
    const sensitivity = Number(motionSensitivityInput.value);
    tuning.maxDeltaPerFrame = 0.02 + sensitivity * 0.02;
    tuning.deadZone = clamp(0.0035 - sensitivity * 0.0012, 0.0012, 0.0035);
    tuning.pinchDeadZone = clamp(0.0026 - sensitivity * 0.0008, 0.001, 0.0026);
    tuning.handSmooth = Number(stabilityInput.value);
    tuning.cursorSmoothSlow = clamp(tuning.handSmooth * 0.4, 0.08, 0.28);
    tuning.cursorSmoothFast = clamp(tuning.handSmooth + 0.08, 0.2, 0.55);
    tuning.minConfidence = Number(minConfidenceInput.value);
  }
  motionSensitivityInput.addEventListener("input", updateTuningFromInputs);
  stabilityInput.addEventListener("input", updateTuningFromInputs);
  minConfidenceInput.addEventListener("input", updateTuningFromInputs);

  const sliders = ["brightness", "contrast", "saturation", "exposure", "temperature", "sharpness"];
  sliders.forEach((k) => {
    const el = document.getElementById(k);
    el.addEventListener("input", () => {
      pushHistory();
      state.edit[k] = Number(el.value);
    });
  });

  function pushHistory() {
    state.history.push({ ...state.edit });
    if (state.history.length > 30) state.history.shift();
    state.future.length = 0;
  }

  function syncSliderValues() {
    sliders.forEach((k) => {
      document.getElementById(k).value = String(state.edit[k]);
    });
  }

  function applyDemoGesture(now) {
    const x = (Math.sin(now / 750) + 1) / 2;
    const y = (Math.cos(now / 900) + 1) / 2;
    const phase = Math.floor(now / 2500) % 4;
    const gesture = phase === 0 ? "cursor" : phase === 1 ? "pinch_nav" : phase === 2 ? "pinch_rotate" : "pinch_color";
    const confidence = 0.8 + 0.15 * Math.sin(now / 400);
    const pinch = 0.06 + 0.03 * Math.sin(now / 450);
    return { x, y, gesture, confidence: Math.max(0, Math.min(1, confidence)), pinch };
  }

  function distance(a, b) {
    return Math.hypot(a.x - b.x, a.y - b.y);
  }

  function detectCombo(hand) {
    const thumb = hand[4];
    const index = hand[8];
    const middle = hand[12];
    const ring = hand[16];
    const pinky = hand[20];
    const wrist = hand[0];

    const dIndex = distance(thumb, index);
    const dMiddle = distance(thumb, middle);
    const dRing = distance(thumb, ring);
    const spread = distance(index, pinky);
    const palm = distance(wrist, middle);

    if (spread < 0.11 && palm < 0.12) return { combo: "poing", gesture: "none", confidence: 0.9, pinch: 0 };
    if (spread > 0.36) return { combo: "main_ouverte", gesture: "open_palm", confidence: 0.85, pinch: 0 };
    if (dIndex < 0.06) return { combo: "pinch_index", gesture: "pinch_nav", confidence: 1 - dIndex / 0.06, pinch: dIndex };
    if (dMiddle < 0.065) return { combo: "pinch_majeur", gesture: "pinch_rotate", confidence: 1 - dMiddle / 0.065, pinch: dMiddle };
    if (dRing < 0.07) return { combo: "pinch_annulaire", gesture: "pinch_color", confidence: 1 - dRing / 0.07, pinch: dRing };
    return { combo: "index_curseur", gesture: "cursor", confidence: 0.6, pinch: 0 };
  }

  function startCalibration(now) {
    state.calibration.running = true;
    state.calibration.startTs = now || performance.now();
    state.calibration.samples = [];
    state.calibration.pinchSamples = [];
    calibrationStatus.textContent = "Calibration: en cours... bouge la main naturellement + fais 2-3 pinch.";
  }

  function finishCalibration() {
    const motionValues = state.calibration.samples;
    const pinchValues = state.calibration.pinchSamples;
    state.calibration.running = false;

    if (motionValues.length < 20) {
      calibrationStatus.textContent = "Calibration: trop peu de données. Recommence en bougeant plus.";
      return;
    }

    const sortedMotion = [...motionValues].sort((a, b) => a - b);
    const p80 = sortedMotion[Math.floor(sortedMotion.length * 0.8)];
    const p40 = sortedMotion[Math.floor(sortedMotion.length * 0.4)];
    const sortedPinch = pinchValues.length ? [...pinchValues].sort((a, b) => a - b) : [0.03, 0.04, 0.05];
    const pinchP30 = sortedPinch[Math.floor(sortedPinch.length * 0.3)];

    const sensitivity = clamp((p80 * 2200), 0.55, 1.7);
    motionSensitivityInput.value = String(sensitivity.toFixed(2));
    const stability = clamp(0.5 - p40 * 1200, 0.18, 0.55);
    stabilityInput.value = String(stability.toFixed(2));
    const minConf = clamp(0.62 - pinchP30 * 2.2, 0.4, 0.7);
    minConfidenceInput.value = String(minConf.toFixed(2));
    updateTuningFromInputs();

    calibrationStatus.textContent = `Calibration: OK (sens=${motionSensitivityInput.value}, stabilité=${stabilityInput.value}, conf=${minConfidenceInput.value})`;
  }

  function smoothHandLandmarks(current, incoming, alpha) {
    if (!incoming) return null;
    if (!current) return incoming.map((p) => ({ x: p.x, y: p.y, z: p.z || 0 }));
    return incoming.map((p, i) => ({
      x: current[i].x + alpha * (p.x - current[i].x),
      y: current[i].y + alpha * (p.y - current[i].y),
      z: (current[i].z || 0) + alpha * ((p.z || 0) - (current[i].z || 0))
    }));
  }

  function drawDebugHand(hand) {
    debugCtx.clearRect(0, 0, debugCanvas.width, debugCanvas.height);
    debugCtx.fillStyle = "rgba(2, 6, 23, 0.1)";
    debugCtx.fillRect(0, 0, debugCanvas.width, debugCanvas.height);
    if (!hand) return;

    const fingerLabels = [
      { i: 4, label: "POUCE" },
      { i: 8, label: "INDEX" },
      { i: 12, label: "MAJEUR" },
      { i: 16, label: "ANNULAIRE" },
      { i: 20, label: "AURICULAIRE" }
    ];

    debugCtx.strokeStyle = "#22d3ee";
    debugCtx.lineWidth = 2;
    for (let i = 0; i < hand.length; i += 1) {
      const p = hand[i];
      const x = p.x * debugCanvas.width;
      const y = p.y * debugCanvas.height;
      debugCtx.beginPath();
      debugCtx.arc(x, y, 4, 0, Math.PI * 2);
      debugCtx.stroke();
    }

    debugCtx.fillStyle = "#f8fafc";
    debugCtx.font = "12px Segoe UI";
    fingerLabels.forEach((f) => {
      const p = hand[f.i];
      const x = p.x * debugCanvas.width;
      const y = p.y * debugCanvas.height;
      debugCtx.fillText(f.label, x + 6, y - 6);
    });
  }

  function smooth(prev, next, alpha) {
    return {
      x: prev.x + alpha * (next.x - prev.x),
      y: prev.y + alpha * (next.y - prev.y)
    };
  }

  function clamp(v, min, max) {
    return Math.min(max, Math.max(min, v));
  }

  function applyGesture(delta, pinch) {
    const dx = Math.abs(delta.x) < tuning.deadZone ? 0 : clamp(delta.x, -tuning.maxDeltaPerFrame, tuning.maxDeltaPerFrame);
    const dy = Math.abs(delta.y) < tuning.deadZone ? 0 : clamp(delta.y, -tuning.maxDeltaPerFrame, tuning.maxDeltaPerFrame);
    const dp = Math.abs(pinch) < tuning.pinchDeadZone ? 0 : pinch;

    if (state.gesture === "pinch_nav") {
      state.edit.zoom = clamp(state.edit.zoom + dp * 0.02, 0.2, 8);
      state.edit.panX += dx * 520;
      state.edit.panY += dy * 520;
    } else if (state.gesture === "pinch_rotate") {
      state.edit.rotation += dx * 110;
    } else if (state.gesture === "pinch_color") {
      state.edit.brightness = clamp(state.edit.brightness - dy * 0.8, -1, 1);
      state.edit.contrast = clamp(state.edit.contrast + dx * 0.5, 0.2, 2.5);
      syncSliderValues();
    }
  }

  function render() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.fillStyle = "#020617";
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    if (!state.image) {
      ctx.fillStyle = "#64748b";
      ctx.font = "28px Segoe UI";
      ctx.fillText("Importe une photo pour commencer", 380, 360);
    } else {
      const e = state.edit;
      ctx.save();
      ctx.translate(canvas.width / 2 + e.panX, canvas.height / 2 + e.panY);
      ctx.rotate((e.rotation * Math.PI) / 180);
      ctx.scale(e.zoom, e.zoom);
      ctx.filter = [
        `brightness(${1 + e.brightness + e.exposure})`,
        `contrast(${e.contrast})`,
        `saturate(${e.saturation})`,
        `hue-rotate(${e.temperature * 8}deg)`
      ].join(" ");
      const ratio = Math.min((canvas.width * 0.8) / state.image.width, (canvas.height * 0.8) / state.image.height);
      const w = state.image.width * ratio;
      const h = state.image.height * ratio;
      ctx.drawImage(state.image, -w / 2, -h / 2, w, h);
      ctx.restore();
    }

    ctx.fillStyle = "#0ea5e9";
    const cx = state.cursor.x * canvas.width;
    const cy = state.cursor.y * canvas.height;
    ctx.beginPath();
    ctx.arc(cx, cy, 7, 0, Math.PI * 2);
    ctx.fill();
  }

  function updateHud() {
    gestureLabel.textContent = state.gesture;
    comboLabel.textContent = state.combo;
    confidenceLabel.textContent = Math.round(state.confidence * 100) + "%";
    confidenceBar.style.width = Math.round(state.confidence * 100) + "%";
    cursorLabel.textContent = state.cursor.x.toFixed(2) + ", " + state.cursor.y.toFixed(2);
  }

  function tick(now) {
    const gestureInputActive = state.demo || state.camOn;

    if (gestureInputActive && state.camOn && state.hand) {
      const dt = state.lastTs > 0 ? now - state.lastTs : 16;
      state.lastTs = now;
      state.smoothedHand = smoothHandLandmarks(state.smoothedHand, state.hand, tuning.handSmooth);

      const comboRaw = detectCombo(state.smoothedHand);
      if (comboRaw.combo !== state.candidateCombo) {
        state.candidateCombo = comboRaw.combo;
        state.candidateSince = now;
      }
      const candidateStable = now - state.candidateSince >= tuning.gestureDebounceMs;
      const acceptedCombo = candidateStable ? comboRaw : { combo: state.combo, gesture: state.gesture, confidence: state.confidence, pinch: state.last ? state.last.pinch : 0 };

      const indexTip = state.smoothedHand[8];
      const speed = state.last ? Math.hypot(indexTip.x - state.last.x, indexTip.y - state.last.y) / Math.max(1, dt) : 0;
      const cursorAlpha = speed > 0.002 ? tuning.cursorSmoothFast : tuning.cursorSmoothSlow;
      state.cursor = smooth(state.cursor, { x: indexTip.x, y: indexTip.y }, cursorAlpha);

      if (acceptedCombo.confidence >= tuning.minConfidence) {
        state.gesture = acceptedCombo.gesture;
        state.combo = acceptedCombo.combo;
        state.confidence = Math.max(0, Math.min(1, acceptedCombo.confidence));
      } else {
        state.gesture = "none";
        state.combo = "incertain";
        state.confidence = acceptedCombo.confidence;
      }

      if (state.last) {
        const delta = { x: state.cursor.x - state.last.x, y: state.cursor.y - state.last.y };
        applyGesture(delta, acceptedCombo.pinch - state.last.pinch);
      }
      if (state.calibration.running) {
        state.calibration.samples.push(speed);
        if (acceptedCombo.combo.startsWith("pinch")) {
          state.calibration.pinchSamples.push(acceptedCombo.pinch);
        }
        const elapsed = now - state.calibration.startTs;
        const left = Math.max(0, Math.ceil((state.calibration.durationMs - elapsed) / 1000));
        calibrationStatus.textContent = `Calibration: en cours... ${left}s`;
        if (elapsed >= state.calibration.durationMs) {
          finishCalibration();
        }
      }
      state.last = { x: state.cursor.x, y: state.cursor.y, pinch: acceptedCombo.pinch };
      drawDebugHand(state.smoothedHand);
    } else if (gestureInputActive && state.demo) {
      const frame = applyDemoGesture(now);
      state.cursor = smooth(state.cursor, { x: frame.x, y: frame.y }, tuning.cursorSmoothSlow);
      state.gesture = frame.gesture;
      state.combo = "demo_auto";
      state.confidence = frame.confidence;

      if (state.last) {
        const delta = { x: state.cursor.x - state.last.x, y: state.cursor.y - state.last.y };
        applyGesture(delta, frame.pinch - state.last.pinch);
      }
      state.last = { x: state.cursor.x, y: state.cursor.y, pinch: frame.pinch };
      drawDebugHand(null);
    } else {
      // Sans mode démo (et sans modèle webcam réel branché), on coupe totalement les gestes.
      state.gesture = "none";
      state.combo = "aucun";
      state.confidence = 0;
      state.last = null;
      state.smoothedHand = null;
      drawDebugHand(null);
    }

    render();
    updateHud();
    requestAnimationFrame(tick);
  }

  fileInput.addEventListener("change", (e) => {
    const file = e.target.files && e.target.files[0];
    if (!file) return;
    const img = new Image();
    img.onload = () => {
      state.image = img;
      state.edit.panX = 0;
      state.edit.panY = 0;
      state.edit.zoom = 1;
    };
    img.src = URL.createObjectURL(file);
  });

  undoBtn.addEventListener("click", () => {
    if (!state.history.length) return;
    state.future.unshift({ ...state.edit });
    state.edit = state.history.pop();
    syncSliderValues();
  });

  redoBtn.addEventListener("click", () => {
    if (!state.future.length) return;
    state.history.push({ ...state.edit });
    state.edit = state.future.shift();
    syncSliderValues();
  });

  resetBtn.addEventListener("click", () => {
    pushHistory();
    state.edit = {
      zoom: 1, rotation: 0, panX: 0, panY: 0, brightness: 0, contrast: 1, saturation: 1, exposure: 0, temperature: 0, sharpness: 0
    };
    syncSliderValues();
  });

  toggleDemoBtn.addEventListener("click", () => {
    state.demo = !state.demo;
    toggleDemoBtn.textContent = state.demo ? "Mode démo ON" : "Mode démo";
  });

  toggleCamBtn.addEventListener("click", async () => {
    if (state.camOn) {
      if (camPreview.srcObject) {
        camPreview.srcObject.getTracks().forEach((t) => t.stop());
      }
      camPreview.srcObject = null;
      state.camOn = false;
      state.hand = null;
      state.smoothedHand = null;
      if (state.cameraEngine && typeof state.cameraEngine.stop === "function") {
        state.cameraEngine.stop();
      }
      toggleCamBtn.textContent = "Activer caméra";
      return;
    }
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: {
          width: { ideal: 1280 },
          height: { ideal: 720 },
          frameRate: { ideal: 60, min: 30 },
          facingMode: "user"
        },
        audio: false
      });
      camPreview.srcObject = stream;
      await camPreview.play().catch(() => undefined);
      const track = stream.getVideoTracks()[0];
      if (track && typeof track.applyConstraints === "function") {
        track
          .applyConstraints({
            width: { ideal: 1280 },
            height: { ideal: 720 },
            frameRate: { ideal: 60 }
          })
          .catch(() => undefined);
      }
      state.camOn = true;
      toggleCamBtn.textContent = "Pause caméra";

      if (window.Hands) {
        if (!state.handsEngine) {
          state.handsEngine = new window.Hands({
            locateFile: (file) => `https://cdn.jsdelivr.net/npm/@mediapipe/hands/${file}`
          });
          state.handsEngine.setOptions({
            maxNumHands: 1,
            modelComplexity: 1,
            minDetectionConfidence: 0.5,
            minTrackingConfidence: 0.45
          });
          state.handsEngine.onResults((results) => {
            state.hand = results.multiHandLandmarks && results.multiHandLandmarks[0] ? results.multiHandLandmarks[0] : null;
          });
        }

        if (window.Camera) {
          state.cameraEngine = new window.Camera(camPreview, {
            onFrame: async () => {
              if (state.handsEngine) await state.handsEngine.send({ image: camPreview });
            },
            width: 640,
            height: 360
          });
          state.cameraEngine.start();
        }
      }
      calibrationStatus.textContent = "Calibration: prête (tu peux lancer Calibration auto).";
    } catch (err) {
      alert("Permission caméra refusée ou indisponible.");
    }
  });

  startCalibrationBtn.addEventListener("click", () => {
    if (!state.camOn) {
      calibrationStatus.textContent = "Calibration: active d'abord la caméra.";
      return;
    }
    startCalibration(performance.now());
  });

  updateTuningFromInputs();
  syncSliderValues();
  requestAnimationFrame(tick);
})();
