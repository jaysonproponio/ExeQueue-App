const apiEndpoints = {
  currentQueue: '../backend/api/current_queue.php',
  nextQueue: '../backend/api/next_queue.php',
  skipQueue: '../backend/api/skip_queue.php',
  continueQueue: '../backend/api/continue_queue.php',
  notificationBatch: '../backend/api/send_notification.php',
};

const appState = {
  board: createEmptyBoard(),
  lastAnnouncedQueue: null,
  actionInFlight: false,
};

document.addEventListener('DOMContentLoaded', () => {
  initializeNavigation();
  initializeDashboard();
  initializeQrDisplay();
  initializeQueueDisplay();
});

function initializeNavigation() {
  const navItems = Array.from(document.querySelectorAll('.nav-item'));
  if (navItems.length === 0) {
    return;
  }

  const sectionNavItems = navItems.filter((item) => {
    const href = item.getAttribute('href') || '';
    return href.startsWith('#');
  });

  sectionNavItems.forEach((item) => {
    item.addEventListener('click', () => {
      sectionNavItems.forEach((navItem) => navItem.classList.remove('active'));
      item.classList.add('active');
    });
  });

  const sections = sectionNavItems
    .map((item) => document.querySelector(item.getAttribute('href')))
    .filter(Boolean);

  if (sections.length === 0 || !('IntersectionObserver' in window)) {
    return;
  }

  const observer = new IntersectionObserver(
    (entries) => {
      const visibleEntry = entries.find((entry) => entry.isIntersecting);
      if (!visibleEntry?.target.id) {
        return;
      }

      sectionNavItems.forEach((item) => {
        const isActive = item.getAttribute('href') === `#${visibleEntry.target.id}`;
        item.classList.toggle('active', isActive);
      });
    },
    {
      rootMargin: '-20% 0px -55% 0px',
      threshold: 0.05,
    },
  );

  sections.forEach((section) => observer.observe(section));
}

function initializeDashboard() {
  const tableBody = document.getElementById('queueTableBody');
  if (!tableBody) {
    return;
  }

  document
    .getElementById('nextQueueButton')
    ?.addEventListener('click', handleNextQueue);
  document
    .getElementById('skipQueueButton')
    ?.addEventListener('click', handleSkipQueue);
  document
    .getElementById('continueSkippedButton')
    ?.addEventListener('click', handleContinueSkippedQueue);

  updateActionButtons();
  refreshDashboard({
    statusMessage: 'Loading live queue data...',
    statusVariant: 'info',
  });
  window.setInterval(() => refreshDashboard(), 5000);
}

function initializeQrDisplay() {
  const qrImage = document.getElementById('qrImage');
  if (!qrImage) {
    return;
  }

  document
    .getElementById('refreshQrButton')
    ?.addEventListener('click', refreshQrDisplay);

  refreshQrDisplay();
  window.setInterval(refreshQrDisplay, 30000);
}

function initializeQueueDisplay() {
  const nowServing = document.getElementById('displayNowServing');
  if (!nowServing) {
    return;
  }

  refreshQueueDisplay({
    statusMessage: 'Waiting for live queue data...',
    statusVariant: 'info',
  });
  window.setInterval(refreshQueueDisplay, 5000);
}

async function refreshDashboard(options = {}) {
  const {
    statusMessage = '',
    statusVariant = 'info',
  } = options;

  if (statusMessage) {
    setBannerState('dashboardMessage', statusVariant, statusMessage);
  }

  try {
    const board = await fetchCurrentQueue();
    renderDashboard(board);

    const hasQueues = board.queues.length > 0;
    setBannerState(
      'dashboardMessage',
      hasQueues ? 'success' : 'info',
      hasQueues
        ? 'Dashboard synced successfully.'
        : 'Database is connected, but there are no queue records yet.',
    );
  } catch (error) {
    renderDashboard(createEmptyBoard());
    setText('dashboardConnectionStatus', 'Offline');
    setText('dashboardLastUpdated', 'Unavailable');
    setBannerState(
      'dashboardMessage',
      'error',
      getErrorMessage(error, 'Unable to reach the queue backend.'),
    );
  }
}

async function refreshQrDisplay() {
  setBannerState(
    'qrStatusMessage',
    'info',
    'Refreshing queue token from live board state...',
  );

  try {
    const board = await fetchCurrentQueue();
    const qrToken = buildQrToken(board.now_serving);

    appState.board = board;
    setText('qrTokenValue', qrToken);
    setText('qrCurrentQueue', board.now_serving);
    renderQrCode(qrToken);

    if (board.queues.length === 0) {
      setBannerState(
        'qrStatusMessage',
        'info',
        'No active queue yet. QR token is ready for the first student.',
      );
    }
  } catch (error) {
    setText('qrTokenValue', 'Token unavailable');
    setText('qrCurrentQueue', 'A000');
    setBannerState(
      'qrStatusMessage',
      'error',
      getErrorMessage(error, 'Unable to prepare the QR token.'),
    );
  }
}

async function refreshQueueDisplay(options = {}) {
  const {
    statusMessage = '',
    statusVariant = 'info',
  } = options;

  if (statusMessage) {
    setBannerState('displayStatusMessage', statusVariant, statusMessage);
  }

  try {
    const board = await fetchCurrentQueue();
    renderQueueDisplay(board);

    const hasQueues = board.queues.length > 0;
    setBannerState(
      'displayStatusMessage',
      hasQueues ? 'success' : 'info',
      hasQueues
        ? 'Live board synced successfully.'
        : 'No queues yet. The board will update when the first student joins.',
    );
  } catch (error) {
    renderQueueDisplay(createEmptyBoard());
    setBannerState(
      'displayStatusMessage',
      'error',
      getErrorMessage(error, 'Unable to load the live queue board.'),
    );
  }
}

async function handleNextQueue() {
  if (appState.actionInFlight) {
    return;
  }

  await runDashboardAction({
    endpoint: apiEndpoints.nextQueue,
    payload: { processed_by: 'cashier_web' },
    successMessage: 'Queue advanced successfully.',
    sendNotifications: true,
  });
}

async function handleSkipQueue() {
  if (appState.actionInFlight) {
    return;
  }

  await runDashboardAction({
    endpoint: apiEndpoints.skipQueue,
    payload: {},
    successMessage: 'Active queue skipped successfully.',
    sendNotifications: true,
  });
}

async function handleContinueSkippedQueue() {
  if (appState.actionInFlight) {
    return;
  }

  const skippedQueue = appState.board.queues.find(
    (queue) => queue.status === 'SKIPPED',
  );

  if (!skippedQueue) {
    setBannerState(
      'dashboardMessage',
      'info',
      'There is no skipped queue to continue.',
    );
    return;
  }

  await runDashboardAction({
    endpoint: apiEndpoints.continueQueue,
    payload: { queue_number: skippedQueue.queue_number },
    successMessage: `Skipped queue ${skippedQueue.queue_number} moved back to waiting.`,
  });
}

async function runDashboardAction({
  endpoint,
  payload,
  successMessage,
  sendNotifications = false,
}) {
  appState.actionInFlight = true;
  updateActionButtons();
  setBannerState('dashboardMessage', 'info', 'Applying cashier action...');

  try {
    const response = await fetchJson(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const board = normalizeBoard(response);
    appState.board = board;
    renderDashboard(board);

    if (sendNotifications) {
      sendNotificationBatch();
    }

    setBannerState('dashboardMessage', 'success', successMessage);
  } catch (error) {
    setBannerState(
      'dashboardMessage',
      'error',
      getErrorMessage(error, 'Unable to complete the cashier action.'),
    );
  } finally {
    appState.actionInFlight = false;
    updateActionButtons();
  }
}

async function fetchCurrentQueue() {
  const payload = await fetchJson(apiEndpoints.currentQueue);
  const board = normalizeBoard(payload);
  appState.board = board;
  updateActionButtons();
  return board;
}

async function sendNotificationBatch() {
  try {
    await fetchJson(apiEndpoints.notificationBatch, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ threshold: 5 }),
    });
  } catch (_) {
    // Notification payload generation is non-blocking for dashboard actions.
  }
}

async function fetchJson(url, options = {}) {
  const response = await fetch(url, {
    cache: 'no-store',
    ...options,
  });

  let payload;
  try {
    payload = await response.json();
  } catch (_) {
    throw new Error(`Invalid response from ${url}.`);
  }

  if (!response.ok || payload.success === false) {
    throw new Error(payload.message || `Request failed with ${response.status}.`);
  }

  return payload;
}

function renderDashboard(board) {
  setText('dashboardNowServing', board.now_serving);
  setText('dashboardConnectionStatus', 'Online');
  setText('dashboardTotalQueues', String(board.queues.length));
  setText('dashboardLastUpdated', formatTimestamp(board.updated_at));

  renderQueuePills(
    'dashboardNextQueue',
    board.next_queues,
    'queue-pill',
    'queue-pill-empty',
    'No queued students',
  );
  renderQueueTable(board.queues);
  renderMetrics(board.queues);
  updateActionButtons();
}

function renderMetrics(queues) {
  setText('waitingCount', String(countByStatus(queues, 'WAITING')));
  setText('calledCount', String(countByStatus(queues, 'CALLED')));
  setText('skippedCount', String(countByStatus(queues, 'SKIPPED')));
  setText('doneCount', String(countByStatus(queues, 'DONE')));
}

function renderQueueTable(queues) {
  const tableBody = document.getElementById('queueTableBody');
  if (!tableBody) {
    return;
  }

  if (queues.length === 0) {
    tableBody.innerHTML = `
      <tr>
        <td colspan="4" class="empty-table-cell">No queue records yet.</td>
      </tr>
    `;
    return;
  }

  tableBody.innerHTML = queues
    .map(
      (item) => `
        <tr>
          <td><strong>${escapeHtml(item.queue_number)}</strong></td>
          <td>${escapeHtml(item.student_name)}</td>
          <td>${escapeHtml(item.transaction_type)}</td>
          <td>
            <span class="status-tag status-${item.status.toLowerCase()}">
              ${escapeHtml(item.status)}
            </span>
          </td>
        </tr>
      `,
    )
    .join('');
}

function renderQueueDisplay(board) {
  setText('displayNowServing', board.now_serving);
  renderQueuePills(
    'displayNextQueue',
    board.next_queues,
    'board-queue-pill',
    'board-queue-pill-empty',
    'No queued students',
  );

  if (appState.lastAnnouncedQueue === null) {
    appState.lastAnnouncedQueue = board.now_serving;
    return;
  }

  if (
    board.now_serving !== 'A000' &&
    board.now_serving !== appState.lastAnnouncedQueue
  ) {
    announceQueue(board.now_serving);
  }

  appState.lastAnnouncedQueue = board.now_serving;
}

function renderQrCode(qrToken) {
  const qrImage = document.getElementById('qrImage');
  const fallbackCanvas = document.getElementById('qrCanvas');
  if (!(qrImage instanceof HTMLImageElement)) {
    return;
  }

  const qrUrl =
    'https://api.qrserver.com/v1/create-qr-code/?size=360x360&data=' +
    encodeURIComponent(qrToken);

  qrImage.onload = () => {
    qrImage.hidden = false;
    if (fallbackCanvas instanceof HTMLCanvasElement) {
      fallbackCanvas.hidden = true;
    }

    setBannerState(
      'qrStatusMessage',
      'success',
      'QR token generated successfully.',
    );
  };

  qrImage.onerror = () => {
    qrImage.hidden = true;

    if (fallbackCanvas instanceof HTMLCanvasElement) {
      fallbackCanvas.hidden = false;
      renderFallbackQrCanvas(fallbackCanvas, qrToken);
    }

    setBannerState(
      'qrStatusMessage',
      'error',
      'Online QR image service is unavailable. The token below is still valid for manual testing.',
    );
  };

  qrImage.src = qrUrl;
}

function renderFallbackQrCanvas(canvas, seed) {
  const context = canvas.getContext('2d');
  if (!context) {
    return;
  }

  const dimension = 29;
  const cell = canvas.width / dimension;

  context.clearRect(0, 0, canvas.width, canvas.height);
  context.fillStyle = '#ffffff';
  context.fillRect(0, 0, canvas.width, canvas.height);

  for (let row = 0; row < dimension; row += 1) {
    for (let column = 0; column < dimension; column += 1) {
      const value = seededValue(seed, row, column);
      if (value > 0.54) {
        context.fillStyle = column % 2 === 0 ? '#10243e' : '#1a73e8';
        context.fillRect(column * cell, row * cell, cell - 1, cell - 1);
      }
    }
  }

  drawFinder(context, cell, 1, 1);
  drawFinder(context, cell, 21, 1);
  drawFinder(context, cell, 1, 21);
}

function renderQueuePills(
  elementId,
  queues,
  defaultClassName,
  emptyClassName,
  emptyLabel,
) {
  const target = document.getElementById(elementId);
  if (!target) {
    return;
  }

  if (queues.length === 0) {
    target.innerHTML = `<span class="${defaultClassName} ${emptyClassName}">${escapeHtml(emptyLabel)}</span>`;
    return;
  }

  target.innerHTML = queues
    .map(
      (queueNumber) =>
        `<span class="${defaultClassName}">${escapeHtml(queueNumber)}</span>`,
    )
    .join('');
}

function updateActionButtons() {
  const nextButton = document.getElementById('nextQueueButton');
  const skipButton = document.getElementById('skipQueueButton');
  const continueButton = document.getElementById('continueSkippedButton');

  if (!(nextButton instanceof HTMLButtonElement)) {
    return;
  }

  const queues = appState.board.queues;
  const hasWaiting = queues.some((queue) => queue.status === 'WAITING');
  const hasCalled = queues.some((queue) => queue.status === 'CALLED');
  const hasSkipped = queues.some((queue) => queue.status === 'SKIPPED');
  const disableAll = appState.actionInFlight;

  nextButton.disabled = disableAll || (!hasWaiting && !hasCalled);

  if (skipButton instanceof HTMLButtonElement) {
    skipButton.disabled = disableAll || !hasCalled;
  }

  if (continueButton instanceof HTMLButtonElement) {
    continueButton.disabled = disableAll || !hasSkipped;
  }
}

function normalizeBoard(payload) {
  const queues = Array.isArray(payload.queues)
    ? payload.queues.map(normalizeQueue)
    : [];

  const nextQueues = Array.isArray(payload.next_queues)
    ? payload.next_queues
        .map((queueNumber) => String(queueNumber || '').trim())
        .filter(Boolean)
    : [];

  return {
    now_serving: String(payload.now_serving || 'A000').trim() || 'A000',
    next_queues: nextQueues,
    queues,
    updated_at: payload.updated_at || null,
  };
}

function normalizeQueue(queue) {
  return {
    queue_number: String(queue.queue_number || 'A000').trim() || 'A000',
    student_name: String(queue.student_name || 'Unknown Student').trim() || 'Unknown Student',
    transaction_type:
      String(queue.transaction_type || 'Transaction not set').trim() ||
      'Transaction not set',
    status: normalizeStatus(queue.status),
  };
}

function normalizeStatus(status) {
  const normalized = String(status || 'WAITING').trim().toUpperCase();
  const validStatuses = new Set(['WAITING', 'CALLED', 'SKIPPED', 'DONE']);
  return validStatuses.has(normalized) ? normalized : 'WAITING';
}

function buildQrToken(nowServing) {
  const queueNumber = String(nowServing || 'A000').trim() || 'A000';
  const timestamp = new Date().toISOString().replace(/\D/g, '').slice(-12);
  return `JOIN-${queueNumber}-${timestamp}`;
}

function createEmptyBoard() {
  return {
    now_serving: 'A000',
    next_queues: [],
    queues: [],
    updated_at: null,
  };
}

function countByStatus(queues, status) {
  return queues.filter((queue) => queue.status === status).length;
}

function formatTimestamp(value) {
  if (!value) {
    return 'Waiting';
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return 'Waiting';
  }

  return date.toLocaleTimeString([], {
    hour: 'numeric',
    minute: '2-digit',
  });
}

function setBannerState(elementId, variant, message) {
  const banner = document.getElementById(elementId);
  if (!banner) {
    return;
  }

  banner.textContent = message;
  banner.classList.remove(
    'status-banner-info',
    'status-banner-success',
    'status-banner-error',
  );
  banner.classList.add(`status-banner-${variant}`);
}

function setText(elementId, value) {
  const target = document.getElementById(elementId);
  if (target) {
    target.textContent = value;
  }
}

function getErrorMessage(error, fallbackMessage) {
  if (error instanceof Error && error.message.trim() !== '') {
    return error.message;
  }

  return fallbackMessage;
}

function announceQueue(queueNumber) {
  if (!('speechSynthesis' in window)) {
    return;
  }

  const utterance = new SpeechSynthesisUtterance(
    `Queue number ${queueNumber} please proceed to the cashier window.`,
  );
  utterance.rate = 0.95;
  utterance.pitch = 1;
  window.speechSynthesis.cancel();
  window.speechSynthesis.speak(utterance);
}

function drawFinder(context, cell, x, y) {
  context.fillStyle = '#10243e';
  context.fillRect(x * cell, y * cell, cell * 7, cell * 7);
  context.fillStyle = '#ffffff';
  context.fillRect((x + 1) * cell, (y + 1) * cell, cell * 5, cell * 5);
  context.fillStyle = '#34a853';
  context.fillRect((x + 2) * cell, (y + 2) * cell, cell * 3, cell * 3);
}

function seededValue(seed, row, column) {
  const combined = `${seed}-${row}-${column}`;
  let hash = 0;

  for (let index = 0; index < combined.length; index += 1) {
    hash = (hash << 5) - hash + combined.charCodeAt(index);
    hash |= 0;
  }

  return Math.abs(Math.sin(hash)) % 1;
}

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}
