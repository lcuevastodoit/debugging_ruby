// User inline editing and creation functionality
document.addEventListener('DOMContentLoaded', function() {
  const userForms = document.querySelectorAll('form[data-user-id]');
  const newUserForm = document.getElementById('new-user-form');
  const newUserFormContainer = document.getElementById('new-user-form-container');
  const toggleButton = document.getElementById('toggle-new-user-form');
  const toggleButtonText = document.getElementById('toggle-button-text');
  const cancelButton = document.getElementById('cancel-new-user');
  
  // Handle existing user forms (edit forms)
  userForms.forEach(form => {
    // Handle both ajax and turbo events
    form.addEventListener('ajax:success', handleFormSuccess);
    form.addEventListener('turbo:submit-end', handleTurboSuccess);
    form.addEventListener('ajax:error', handleFormError);
    form.addEventListener('turbo:submit-error', handleTurboError);
    
    // Add form validation before submission for edit forms only
    if (form.querySelector('input[name="_method"][value="patch"]')) {
      form.addEventListener('submit', function(event) {
        if (!validateForm(form)) {
          event.preventDefault();
          return false;
        }
      });
    }
  });
  
  // Handle delete forms using event delegation
  document.addEventListener('ajax:success', function(event) {
    handleDeleteSuccess(event);
  });
  
  document.addEventListener('turbo:submit-end', function(event) {
    handleDeleteTurboSuccess(event);
  });
  
  document.addEventListener('ajax:error', function(event) {
    handleDeleteError(event);
  });
  
  function handleFormSuccess(event) {
    const userId = event.target.dataset.userId;
    const response = event.detail && event.detail[0] ? event.detail[0] : {};
    showSuccessMessage(response.message || `User ${userId} updated successfully`);
  }
  
  function handleTurboSuccess(event) {
    if (event.detail.success) {
      const userId = event.target.dataset.userId;
      showSuccessMessage(`User ${userId} updated successfully`);
    }
  }
  
  function handleFormError(event) {
    const userId = event.target.dataset.userId;
    const response = event.detail && event.detail[0] ? event.detail[0] : {};
    
    if (response && response.errors) {
      showErrorMessage(`Failed to update user: ${response.errors.join(', ')}`);
    } else {
      showErrorMessage(`Failed to update user ${userId}`);
    }
  }
  
  function handleTurboError(event) {
    const userId = event.target.dataset.userId;
    showErrorMessage(`Failed to update user ${userId}`);
  }
  
  function handleDeleteSuccess(event) {
    const target = event.target;
    if (target.matches('form[action*="users/"][data-user-id]') && target.querySelector('input[name="_method"][value="delete"]')) {
      const response = event.detail && event.detail[0] ? event.detail[0] : {};
      showSuccessMessage(response.message || 'User deleted successfully');
      removeUserRow(target);
    }
  }
  
  function handleDeleteTurboSuccess(event) {
    const target = event.target;
    if (target.matches('form[action*="users/"][data-user-id]') && target.querySelector('input[name="_method"][value="delete"]')) {
      if (event.detail.success) {
        showSuccessMessage('User deleted successfully');
        removeUserRow(target);
      }
    }
  }
  
  function handleDeleteError(event) {
    const target = event.target;
    if (target.matches('form[action*="users/"][data-user-id]') && target.querySelector('input[name="_method"][value="delete"]')) {
      const response = event.detail && event.detail[0] ? event.detail[0] : {};
      if (response && response.errors) {
        showErrorMessage(`Failed to delete user: ${response.errors.join(', ')}`);
      } else {
        showErrorMessage('Failed to delete user');
      }
    }
  }
  
  function removeUserRow(deleteForm) {
    // Find the parent user row (the edit form)
    const userRow = deleteForm.closest('.grid').querySelector('form[data-user-id]');
    if (userRow && userRow !== deleteForm) {
      userRow.style.transition = 'opacity 0.3s ease-out';
      userRow.style.opacity = '0';
      setTimeout(() => {
        userRow.parentElement.remove(); // Remove the entire grid container
      }, 300);
    }
  }
  
  // Handle new user form toggle
  if (toggleButton) {
    toggleButton.addEventListener('click', function() {
      if (newUserFormContainer.style.display === 'none') {
        showNewUserForm();
      } else {
        hideNewUserForm();
      }
    });
  }
  
  // Handle cancel button
  if (cancelButton) {
    cancelButton.addEventListener('click', function() {
      hideNewUserForm();
      clearNewUserForm();
    });
  }
  
  // Handle new user form submission
  if (newUserForm) {
    newUserForm.addEventListener('ajax:success', function(event) {
      const response = event.detail && event.detail[0] ? event.detail[0] : {};
      showSuccessMessage('User created successfully');
      hideNewUserForm();
      clearNewUserForm();
      window.location.reload();
    });
    
    newUserForm.addEventListener('turbo:submit-end', function(event) {
      if (event.detail.success) {
        showSuccessMessage('User created successfully');
        hideNewUserForm();
        clearNewUserForm();
        window.location.reload();
      }
    });
    
    newUserForm.addEventListener('ajax:error', function(event) {
      const response = event.detail && event.detail[0] ? event.detail[0] : {};
      if (response && response.errors) {
        showErrorMessage(`Failed to create user: ${response.errors.join(', ')}`);
      } else {
        showErrorMessage('Failed to create user');
      }
    });
    
    newUserForm.addEventListener('submit', function(event) {
      if (!validateForm(newUserForm)) {
        event.preventDefault();
        return false;
      }
    });
  }
  
  function showNewUserForm() {
    newUserFormContainer.style.display = 'block';
    toggleButtonText.textContent = 'Cancel';
    newUserForm.querySelector('input[name="user[name]"]').focus();
  }
  
  function hideNewUserForm() {
    newUserFormContainer.style.display = 'none';
    toggleButtonText.textContent = 'Add New User';
  }
  
  function clearNewUserForm() {
    if (newUserForm) {
      newUserForm.reset();
    }
  }
  
  function validateForm(form) {
    const nameField = form.querySelector('input[name="user[name]"]');
    const emailField = form.querySelector('input[name="user[email]"]');
    
    let isValid = true;
    let errors = [];
    
    if (!nameField || !nameField.value.trim()) {
      errors.push('Name is required');
      isValid = false;
    }
    
    if (!emailField || !emailField.value.trim()) {
      errors.push('Email is required');
      isValid = false;
    } else if (!isValidEmail(emailField.value)) {
      errors.push('Please enter a valid email address');
      isValid = false;
    }
    
    if (!isValid) {
      showErrorMessage(errors.join(', '));
    }
    
    return isValid;
  }
  
  function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }
  
  function showSuccessMessage(message) {
    showNotification(message, 'success');
  }
  
  function showErrorMessage(message) {
    showNotification(message, 'error');
  }
  
  function showNotification(message, type) {
    const notification = document.createElement('div');
    notification.className = `fixed top-4 right-4 p-4 rounded-lg text-white z-50 transition-opacity duration-300 ${
      type === 'success' ? 'bg-green-500' : 'bg-red-500'
    }`;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
      notification.style.opacity = '0';
      setTimeout(() => {
        notification.remove();
      }, 300);
    }, 3000);
  }
});