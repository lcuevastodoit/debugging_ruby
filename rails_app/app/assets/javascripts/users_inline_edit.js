// User inline editing functionality
document.addEventListener('DOMContentLoaded', function() {
  const userForms = document.querySelectorAll('form[data-user-id]');
  
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