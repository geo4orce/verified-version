const copyButton = document.querySelector('[data-copy-target]');

if (copyButton) {
  copyButton.hidden = false;

  copyButton.addEventListener('click', async () => {
    const command = document.getElementById(copyButton.dataset.copyTarget);

    if (!command) {
      return;
    }

    try {
      await navigator.clipboard.writeText(command.textContent.trim());
      copyButton.textContent = 'Copied';
    } catch {
      copyButton.textContent = 'Failed';
    }

    window.setTimeout(() => {
      copyButton.textContent = 'Copy';
    }, 1500);
  });
}
