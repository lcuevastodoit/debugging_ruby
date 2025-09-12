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
    form.addEventListener('ajax:success', function(event) {
      const userId = form.dataset.userId;
      showSuccessMessage(`User ${userId} updated successfully`);
    });
    
    form.addEventListener('ajax:error', function(event) {
      const userId = form.dataset.userId;
      showErrorMessage(`Failed to update user ${userId}`);
    });
    
    // Add form validation before submission
    form.addEventListener('submit', function(event) {
      if (!validateForm(form)) {
        event.preventDefault();
        return false;
      }
    });
  });
  
  // Handle delete forms using event delegation
  document.addEventListener('submit', function(event) {
    const form = event.target;
    
    // Check if this is a delete form
    if (form.matches('form[method="post"]') && form.querySelector('input[name="_method"][value="delete"]')) {
      event.preventDefault();
      
      const confirmMessage = form.dataset.confirm;
      if (confirmMessage && !confirm(confirmMessage)) {
        return false;
      }
      
      // Perform AJAX delete
      const formData = new FormData(form);
      
      fetch(form.action, {
        method: 'POST',
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json'
        }
      })
      .then(response => response.json())
      .then(data => {
        if (data.status === 'success') {
          showSuccessMessage(data.message || 'User deleted successfully');
          // Remove the user row
          const userRow = form.closest('.grid');
          if (userRow) {
            userRow.style.transition = 'opacity 0.3s ease-out';
            userRow.style.opacity = '0';
            setTimeout(() => {
              userRow.remove();
            }, 300);
          }
        } else {
          showErrorMessage(data.errors ? data.errors.join(', ') : 'Failed to delete user');
        }
      })
      .catch(error => {
        console.error('Delete error:', error);
        showErrorMessage('Failed to delete user');
      });
    }
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
      showSuccessMessage('User created successfully');
      hideNewUserForm();
      clearNewUserForm();
      window.location.reload();
    });
    
    newUserForm.addEventListener('ajax:error', function(event) {
      showErrorMessage('Failed to create user');
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
    const nameField = newUserForm.querySelector('input[name="user[name]"]');
    if (nameField) nameField.focus();
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