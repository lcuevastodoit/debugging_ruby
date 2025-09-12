// User inline editing and creation functionality
document.addEventListener('DOMContentLoaded', function() {
  const userForms = document.querySelectorAll('form[data-user-id]');
  const deleteLinks = document.querySelectorAll('a[data-method="delete"]');
  const newUserForm = document.getElementById('new-user-form');
  const newUserFormContainer = document.getElementById('new-user-form-container');
  const toggleButton = document.getElementById('toggle-new-user-form');
  const toggleButtonText = document.getElementById('toggle-button-text');
  const cancelButton = document.getElementById('cancel-new-user');
  
  // Handle existing user forms
  userForms.forEach(form => {
    form.addEventListener('ajax:success', function(event) {
      const userId = form.dataset.userId;
      const response = event.detail[0];
      showSuccessMessage(response.message || `User ${userId} updated successfully`);
    });
    
    form.addEventListener('ajax:error', function(event) {
      const userId = form.dataset.userId;
      const response = event.detail[0];
      
      if (response && response.errors) {
        showErrorMessage(`Failed to update user: ${response.errors.join(', ')}`);
      } else {
        showErrorMessage(`Failed to update user ${userId}`);
      }
    });
    
    // Add form validation before submission
    form.addEventListener('submit', function(event) {
      if (!validateForm(form)) {
        event.preventDefault();
        return false;
      }
    });
  });
  
  // Handle delete links
  deleteLinks.forEach(link => {
    link.addEventListener('ajax:success', function(event) {
      const response = event.detail[0];
      showSuccessMessage(response.message || 'User deleted successfully');
      // Remove the user row from the DOM
      const userRow = link.closest('form');
      if (userRow) {
        userRow.style.transition = 'opacity 0.3s ease-out';
        userRow.style.opacity = '0';
        setTimeout(() => {
          userRow.remove();
        }, 300);
      }
    });
    
    link.addEventListener('ajax:error', function(event) {
      const response = event.detail[0];
      if (response && response.errors) {
        showErrorMessage(`Failed to delete user: ${response.errors.join(', ')}`);
      } else {
        showErrorMessage('Failed to delete user');
      }
    });
  });
  
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
      const response = event.detail[0];
      showSuccessMessage('User created successfully');
      hideNewUserForm();
      clearNewUserForm();
      // Reload page to show new user
      window.location.reload();
    });
    
    newUserForm.addEventListener('ajax:error', function(event) {
      const response = event.detail[0];
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
  
  // ...existing validation and notification functions...
  function validateForm(form) {
    const nameField = form.querySelector('input[name="user[name]"]');
    const emailField = form.querySelector('input[name="user[email]"]');
    
    let isValid = true;
    let errors = [];
    
    if (!nameField.value.trim()) {
      errors.push('Name is required');
      isValid = false;
    }
    
    if (!emailField.value.trim()) {
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