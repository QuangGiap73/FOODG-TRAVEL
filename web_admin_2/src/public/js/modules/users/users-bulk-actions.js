(function () {
  document.addEventListener('click', (event) => {
    const actionButton = event.target.closest('[data-action]');
    if (!actionButton) return;

    const action = actionButton.dataset.action;
    const userId = actionButton.dataset.id;

    if (action === 'view') {
      console.log('view user', userId);
    }

    if (action === 'edit') {
      console.log('edit user', userId);
    }

    if (action === 'more') {
      console.log('more actions', userId);
    }
  });
})();
