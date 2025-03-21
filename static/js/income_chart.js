document.addEventListener("DOMContentLoaded", () => {
    // Fetch income summary from the API with default filter set to 'this_year'
    fetchIncome('this_year');
});

function fetchIncome(filterType) {
    fetch(`/api/income-summary?filter=${filterType}`)
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(data => {
            // Prepare data for the chart
            const labels = Object.keys(data);
            const values = Object.values(data);
            const totalAmount = values.reduce((acc, val) => acc + val, 0); // Calculate total amount

            // Access the currency symbol
            const currencySymbol = document.getElementById('currencySymbol').textContent;

            // Format labels to include actual amounts and percentages
            const formattedLabels = labels.map((label, index) => {
                const amount = values[index];
                const percentage = ((amount / totalAmount) * 100).toFixed(2); // Calculate percentage
                return `${label}: ${currencySymbol}${amount.toLocaleString()} (${percentage}%)`; // Format label
            });

            // Update the filter label
            document.getElementById('filterLabel').textContent = `| ${filterType.charAt(0).toUpperCase() + filterType.slice(1).replace('_', ' ')}`;

            // Create or update the doughnut chart
            const ctx = document.querySelector('#incomeChart');
            if (ctx.chart) {
                ctx.chart.data.labels = formattedLabels;
                ctx.chart.data.datasets[0].data = values;
                ctx.chart.update();
            } else {
                ctx.chart = new Chart(ctx, {
                    type: 'doughnut',
                    data: {
                        labels: formattedLabels,
                        datasets: [{
                            label: 'Income',
                            data: values,
                            backgroundColor: [
                                '#60D0AC',
                                '#A0E0D1',
                                '#448570',
                                '#4BBFA0',
                                '#3DAF8C',
                                '#2F9F78',
                                '#228F65'
                            ],
                            hoverOffset: 4
                        }]
                    }
                });
            }
        })
        .catch(error => {
            console.error('Error fetching income summary:', error);
        });
}
