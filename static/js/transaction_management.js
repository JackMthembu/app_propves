function handlePropertySelection(select) {
    const selectedValue = select.value;
    const row = select.closest('tr');
    const transactionAmount = row.querySelector('[data-field="amount"] input').value;

    if (selectedValue === 'all') {
        const propertyCount = select.options.length - 1; // Subtract 1 for the "All Properties" option
        const distributedAmount = (parseFloat(transactionAmount) / propertyCount).toFixed(2);

        // Create new transaction rows for each property
        Array.from(select.options).forEach((option, index) => {
            if (index === 0) return; // Skip "All Properties" option
            
            const newRow = row.cloneNode(true);
            const propertySelect = newRow.querySelector('.property-selector');
            propertySelect.value = option.value;
            
            // Update transaction amount with distributed value
            const amountInput = newRow.querySelector('[data-field="amount"] input');
            amountInput.value = distributedAmount;
            
            row.parentNode.insertBefore(newRow, row.nextSibling);
        });

        // Remove the original row
        row.remove();
    }
}

// Add event listener to property selectors
document.querySelectorAll('.property-selector').forEach(select => {
    select.addEventListener('change', () => handlePropertySelection(select));
});

async function saveTransaction(button) {
    const row = button.closest('tr');
    const transactionId = row.querySelector('.property-selector').dataset.transactionId;
    const data = {
        property_id: row.querySelector('.property-selector').value,
        transaction_date: row.querySelector('[data-field="transaction_date"] input').value,
        description: row.querySelector('[data-field="description"] input').value,
        amount: parseFloat(row.querySelector('[data-field="amount"] input').value),
        is_reconciled: row.querySelector('[data-field="is_reconciled"] input').checked
    };

    try {
        const url = transactionId ? `/api/transaction/${transactionId}` : '/api/transaction';
        const method = transactionId ? 'PUT' : 'POST';
        
        const response = await fetch(url, {
            method: method,
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(data)
        });

        if (!response.ok) throw new Error('Failed to save transaction');

        const result = await response.json();
        
        // Update the row with new data
        if (!transactionId) {
            row.querySelector('.property-selector').dataset.transactionId = result.id;
        }

        Swal.fire({
            icon: 'success',
            title: 'Success!',
            text: 'Transaction saved successfully',
            timer: 2000
        });
    } catch (error) {
        console.error('Error:', error);
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Failed to save transaction'
        });
    }
}

async function deleteTransaction(button) {
    const row = button.closest('tr');
    const transactionId = row.querySelector('.property-selector').dataset.transactionId;

    // If there's no transactionId, it's a new unsaved row
    if (!transactionId) {
        row.remove();
        return;
    }

    try {
        const result = await Swal.fire({
            title: 'Are you sure?',
            text: "You won't be able to revert this!",
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#d33',
            cancelButtonColor: '#3085d6',
            confirmButtonText: 'Yes, delete it!'
        });

        if (result.isConfirmed) {
            const response = await fetch(`/api/transaction/${transactionId}`, {
                method: 'DELETE'
            });

            if (!response.ok) throw new Error('Failed to delete transaction');

            row.remove();
            
            Swal.fire({
                icon: 'success',
                title: 'Deleted!',
                text: 'Transaction has been deleted.',
                timer: 2000
            });
        }
    } catch (error) {
        console.error('Error:', error);
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Failed to delete transaction'
        });
    }
}

function saveAllTransactions() {
    const transactions = [];
    document.querySelectorAll('.editable-row').forEach(row => {
        const transactionId = row.getAttribute('data-id');
        const date = row.querySelector('[data-field="date"] input').value;
        const property = row.querySelector('[data-field="property"] select').value;
        const account = row.querySelector('[data-field="account"] select').value;
        const description = row.querySelector('[data-field="description"] input').value;
        const amount = row.querySelector('[data-field="amount"] input').value;
        const isReconciled = row.querySelector('[data-field="is_reconciled"] input').checked;

        transactions.push({
            id: transactionId,
            date: date,
            property: property,
            account: account,
            description: description,
            amount: amount,
            is_reconciled: isReconciled
        });
    });

    fetch('{{ url_for("transaction_routes.transactions_save") }}', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRFToken': '{{ form.csrf_token }}'
        },
        body: JSON.stringify(transactions)
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            alert('All changes saved successfully!');
            location.reload();
        } else {
            alert('Error saving changes: ' + data.error);
        }
    })
    .catch(error => {
        console.error('Error:', error);
        alert('An error occurred while saving changes.');
    });
}

function addNewTransactionRow() {
    // Create a new row element
    const newRow = document.createElement('tr');
    newRow.classList.add('editable-row');

    // Define the HTML structure for the new row
    newRow.innerHTML = `
        <td class="editable" data-field="date">
            <input type="date" class="form-control form-control-sm" value="">
        </td>
        <td class="editable" data-field="property">
            <select class="form-control form-control-sm property-selector">
                <option value="">Select Property</option>
                {% for property in properties %}
                    <option value="{{ property.id }}">{{ property.title }}</option>
                {% endfor %}
            </select>
        </td>
        <td class="editable" data-field="account">
            <select class="form-control form-control-sm">
                <option value="">Select Account</option>
                {% for account in account_classifications %}
                    <option value="{{ account }}">{{ account }}</option>
                {% endfor %}
            </select>
        </td>
        <td class="editable" data-field="description">
            <input type="text" class="form-control form-control-sm" value="">
        </td>
        <td class="editable" data-field="amount">
            <input type="number" class="form-control form-control-sm" value="0.00" step="0.01">
        </td>
        <td class="editable text-center" data-field="is_reconciled">
            <input type="checkbox" class="form-check-input">
        </td>
        <td>
            <button type="button" class="btn btn-sm btn-danger" onclick="this.closest('tr').remove()">
                <i class="bi bi-trash"></i>
            </button>
        </td>
    `;

    // Append the new row to the table body
    const tableBody = document.querySelector('tbody'); // Adjust the selector to target your specific table body
    tableBody.appendChild(newRow);
}

console.log('Transactions data being sent:', transactions);
