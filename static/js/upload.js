document.addEventListener('DOMContentLoaded', function() {
    const dropZone = document.getElementById('dropZone');
    const fileInput = document.getElementById('fileInput');
    const uploadForm = document.getElementById('aiUploadForm');
    const uploadProgress = document.querySelector('.upload-progress');
    const progressBar = document.querySelector('.progress-bar');
    const uploadStatus = document.getElementById('uploadStatus');
    const selectedFilesContainer = document.querySelector('.selected-files');

    // Prevent default behavior (Prevent file from being opened)
    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
        dropZone.addEventListener(eventName, preventDefaults, false);
    });

    // Highlight the drop zone when dragging files over it
    ['dragenter', 'dragover'].forEach(eventName => {
        dropZone.addEventListener(eventName, highlight, false);
    });

    // Remove highlight when dragging files out
    ['dragleave', 'drop'].forEach(eventName => {
        dropZone.addEventListener(eventName, unhighlight, false);
    });

    // Handle the drop event
    dropZone.addEventListener('drop', handleDrop, false);

    // Handle file input change
    fileInput.addEventListener('change', handleFiles, false);

    // Prevent default behavior
    function preventDefaults(e) {
        e.preventDefault();
        e.stopPropagation();
    }

    // Highlight the drop zone
    function highlight() {
        dropZone.classList.add('highlight');
    }

    // Unhighlight the drop zone
    function unhighlight() {
        dropZone.classList.remove('highlight');
    }

    // Handle dropped files
    function handleDrop(e) {
        const dt = e.dataTransfer;
        const files = dt.files;
        handleFiles(files);
    }

    // Handle selected files
    function handleFiles(files) {
        const fileArray = Array.from(files);
        selectedFilesContainer.innerHTML = ''; // Clear previous files
        fileArray.forEach(file => {
            const listItem = document.createElement('div');
            listItem.textContent = file.name;
            selectedFilesContainer.appendChild(listItem);
        });
        uploadFiles(fileArray);
    }

    // Upload files
    async function uploadFiles(files) {
        const formData = new FormData(uploadForm);
        files.forEach(file => {
            formData.append('files[]', file);
        });

        uploadProgress.classList.remove('d-none');
        uploadStatus.textContent = 'Uploading...';
        progressBar.style.width = '0%';

        try {
            const response = await fetch('/upload-transactions', {
                method: 'POST',
                body: formData
            });

            const result = await response.json();
            if (result.success) {
                uploadStatus.textContent = 'Upload successful!';
                progressBar.style.width = '100%';
                // Handle success (e.g., show preview of transactions)
            } else {
                uploadStatus.textContent = 'Upload failed: ' + result.error;
            }
        } catch (error) {
            uploadStatus.textContent = 'Upload failed: ' + error.message;
        } finally {
            uploadProgress.classList.add('d-none');
        }
    }
}); 