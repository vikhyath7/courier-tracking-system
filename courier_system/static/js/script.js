// Function to dismiss alerts after 5 seconds
document.addEventListener('DOMContentLoaded', function() {
    setTimeout(function() {
        const alerts = document.getElementsByClassName('alert');
        for (let alert of alerts) {
            if (!alert.classList.contains('alert-permanent')) {
                alert.style.display = 'none';
            }
        }
    }, 5000);
});

// Form validation
(function() {
    'use strict'
    const forms = document.querySelectorAll('.needs-validation');
    Array.from(forms).forEach(function(form) {
        form.addEventListener('submit', function(event) {
            if (!form.checkValidity()) {
                event.preventDefault();
                event.stopPropagation();
            }
            form.classList.add('was-validated');
        }, false);
    });
})();