const queueState = {
  queues: [
    {
      queueNumber: 'A021',
      studentName: 'Ana Reyes',
      transactionType: 'Tuition Payment',
      status: 'CALLED',
    },
    {
      queueNumber: 'A022',
      studentName: 'Paolo Cruz',
      transactionType: 'Assessment',
      status: 'WAITING',
    },
    {
      queueNumber: 'A023',
      studentName: 'Mia Santos',
      transactionType: 'Document Request',
      status: 'WAITING',
    },
    {
      queueNumber: 'A024',
      studentName: 'John Villanueva',
      transactionType: 'Balance Inquiry',
      status: 'WAITING',
    },
    {
      queueNumber: 'A025',
      studentName: 'Kyla Fernandez',
      transactionType: 'Tuition Payment',
      status: 'WAITING',
    },
    {
      queueNumber: 'A026',
      studentName: 'Leo Mendoza',
      transactionType: 'Scholarship Clearance',
      status: 'SKIPPED',
    },
  ],
  qrToken: buildQrToken(),
  lastAnnounced: 'A021',
};

document.addEventListener('DOMContentLoaded', () => {
  initializeDashboard();
  initializeQrDisplay();
  initializeQueueDisplay();
});

function initializeDashboard() {
  const tableBody = document.getElementById('queueTableBody');
  if (!tableBody) {
    return;
  }

  renderDashboard();

  document
    .getElementById('nextQueueButton')
    ?.addEventListener('click', handleNextQueue);
  document
    .getElementById('skipQueueButton')
    ?.addEventListener('click', handleSkipQueue);
  document
    .getElementById('continueSkippedButton')
    ?.addEventListener('click', handleContinueSkippedQueue);
}

function initializeQrDisplay() {
  const canvas = document.getElementById('qrCanvas');
  if (!canvas) {
    return;
  }

  refreshQrDisplay();

  document
    .getElementById('refreshQrButton')
    ?.addEventListener('click', refreshQrDisplay);

  window.setInterval(refreshQrDisplay, 30000);
}

function initializeQueueDisplay() {
  const nowServing = document.getElementById('displayNowServing');
  if (!nowServing) {
    return;
  }

  renderQueueDisplay();
  window.setInterval(renderQueueDisplay, 5000);
}

function renderDashboard() {
  const board = getBoardState();

  setText('dashboardNowServing', board.nowServing);
  renderQueuePills('dashboardNextQueue', board.nextQueues, 'queue-pill');
  renderQueueTable();

  setText('waitingCount', countByStatus('WAITING'));
  setText('calledCount', countByStatus('CALLED'));
  setText('skippedCount', countByStatus('SKIPPED'));
  setText('doneCount', countByStatus('DONE'));
}

function renderQueueTable() {
  const tableBody = document.getElementById('queueTableBody');
  if (!tableBody) {
    return;
  }

  tableBody.innerHTML = queueState.queues
    .map(
      (item) => `
        <tr>
          <td><strong>${item.queueNumber}</strong></td>
          <td>${item.studentName}</td>
          <td>${item.transactionType}</td>
          <td>
            <span class="status-tag status-${item.status.toLowerCase()}">
              ${item.status}
            </span>
          </td>
        </tr>
      `,
    )
    .join('');
}

function refreshQrDisplay() {
  queueState.qrToken = buildQrToken();
  renderQrCanvas('qrCanvas', queueState.qrToken);
  setText('qrTokenValue', queueState.qrToken);
  setText('qrCurrentQueue', getBoardState().nowServing);
}

function renderQueueDisplay() {
  const board = getBoardState();
  setText('displayNowServing', board.nowServing);
  renderQueuePills('displayNextQueue', board.nextQueues, 'board-queue-pill');

  if (board.nowServing !== queueState.lastAnnounced) {
    announceQueue(board.nowServing);
    queueState.lastAnnounced = board.nowServing;
  }
}

function handleNextQueue() {
  const activeQueue = queueState.queues.find((queue) => queue.status === 'CALLED');
  if (activeQueue) {
    activeQueue.status = 'DONE';
  }

  const nextWaitingQueue = queueState.queues.find(
    (queue) => queue.status === 'WAITING',
  );

  if (nextWaitingQueue) {
    nextWaitingQueue.status = 'CALLED';
    announceQueue(nextWaitingQueue.queueNumber);
    queueState.lastAnnounced = nextWaitingQueue.queueNumber;
  }

  renderDashboard();
  renderQueueDisplay();
}

function handleSkipQueue() {
  const activeQueue = queueState.queues.find((queue) => queue.status === 'CALLED');
  if (!activeQueue) {
    return;
  }

  activeQueue.status = 'SKIPPED';

  const nextWaitingQueue = queueState.queues.find(
    (queue) => queue.status === 'WAITING',
  );

  if (nextWaitingQueue) {
    nextWaitingQueue.status = 'CALLED';
    announceQueue(nextWaitingQueue.queueNumber);
    queueState.lastAnnounced = nextWaitingQueue.queueNumber;
  }

  renderDashboard();
  renderQueueDisplay();
}

function handleContinueSkippedQueue() {
  const skippedIndex = queueState.queues.findIndex(
    (queue) => queue.status === 'SKIPPED',
  );
  if (skippedIndex === -1) {
    return;
  }

  const [skippedQueue] = queueState.queues.splice(skippedIndex, 1);
  skippedQueue.status = 'WAITING';

  const activeIndex = queueState.queues.findIndex(
    (queue) => queue.status === 'CALLED',
  );
  const insertIndex = activeIndex === -1 ? 0 : activeIndex + 1;
  queueState.queues.splice(insertIndex, 0, skippedQueue);

  renderDashboard();
  renderQueueDisplay();
}

function getBoardState() {
  const activeQueue =
    queueState.queues.find((queue) => queue.status === 'CALLED') ||
    queueState.queues.find((queue) => queue.status === 'DONE');

  const nextQueues = queueState.queues
    .filter((queue) => queue.status === 'WAITING')
    .slice(0, 3)
    .map((queue) => queue.queueNumber);

  return {
    nowServing: activeQueue?.queueNumber ?? 'A000',
    nextQueues,
  };
}

function countByStatus(status) {
  return queueState.queues.filter((queue) => queue.status === status).length;
}

function renderQueuePills(elementId, queues, className) {
  const target = document.getElementById(elementId);
  if (!target) {
    return;
  }

  target.innerHTML = queues
    .map((queueNumber) => `<span class="${className}">${queueNumber}</span>`)
    .join('');
}

function setText(elementId, value) {
  const target = document.getElementById(elementId);
  if (target) {
    target.textContent = value;
  }
}

function buildQrToken() {
  const currentQueue = getBoardState().nowServing;
  const timestamp = Date.now().toString().slice(-6);
  return `JOIN-${currentQueue}-${timestamp}`;
}

function renderQrCanvas(canvasId, seed) {
  const canvas = document.getElementById(canvasId);
  if (!(canvas instanceof HTMLCanvasElement)) {
    return;
  }

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
